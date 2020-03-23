local recordName(category, rate) =
  'component:%s:slo_ok_%s' % [category, rate];

local sloFromRecordingRules(category, param) =
  local slo = {
    rules: error 'must set rules for %sSLO' % category,
    threshold: error 'must set a threshold for %s SLO' % category,
    selectors: [],
  } + param;

  local exprString =
    if std.length(slo.selectors) == 0
    then '%s < bool(%s)'
    else '%s{%s} < bool(%s)';

  [
    {
      record: recordName(category, r.rate),
      expr: exprString %
            if std.length(slo.selectors) == 0
            then [r.record, slo.threshold]
            else [r.record, std.join(',', slo.selectors), slo.threshold],
      labels: r.labels,
      rate:: r.rate,
    }
    for r in slo.rules
  ];

{
  volumeSLO(param):: {
    rules: sloFromRecordingRules('volume', param),
  },

  latencySLO(param):: {
    rules: sloFromRecordingRules('latency', param),
    rulesProductBuilder: [
      {
        record: recordName('latency', r.rate),
        handlers: r.handlers,
        labels: r.labels,
      }
      for r in param.rulesBuilder
    ],
  },

  errorsSLO(param):: {
    rules: sloFromRecordingRules('errors', param),
  },

  availabilitySLO(errorsSLORules, latencySLORulesProductBuilder):: {
    local errorsLength = std.length(errorsSLORules),
    local latencyLength = std.length(latencySLORulesProductBuilder),
    assert latencyLength == errorsLength :
           error 'Non-matching length for input arrays. %d != %d' % [latencyLength, errorsLength],

    local latencyProductRules =
      [
        if std.length(rule.handlers) == 0
        then rule
        else {
          record: std.join(' * ', std.map(function(handler) '%s{%s}' % [
            rule.record,
            handler,
          ], rule.handlers)),
        }
        for rule in latencySLORulesProductBuilder
      ],

    rules: [
      {
        record: 'component:availability:slo_ok_%s' % errorsSLORules[i].rate,
        expr: '%s * %s' % [latencyProductRules[i].record, errorsSLORules[i].record],
        labels: errorsSLORules[i].labels + latencySLORulesProductBuilder[i].labels,
      }
      for i in std.range(0, std.length(errorsSLORules) - 1)

    ],
  },
}
