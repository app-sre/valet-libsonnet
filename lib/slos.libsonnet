local sloFromRecordingRules(category, param) =
  local slo = {
    recordingRules: error 'must set recordingRules for %sSLO' % category,
    threshold: error 'must set a threshold for %s SLO' % category,
    selectors: [],
  } + param;

  local exprString =
    if std.length(slo.selectors) == 0
    then '%s < bool(%s)'
    else '%s{%s} < bool(%s)';

  [
    {
      record: 'component:%s:slo_ok_%s' % [category, r.rate],
      expr: exprString %
            if std.length(slo.selectors) == 0
            then [r.record, slo.threshold]
            else [r.record, std.join(',', slo.selectors), slo.threshold],
      labels: r.labels,
      rate:: r.rate,
    }
    for r in slo.recordingRules
  ];

{
  volumeSLO(param):: {
    rules: sloFromRecordingRules('volume', param),
  },

  latencySLO(param):: {
    rules: sloFromRecordingRules('latency', param),
  },

  errorsSLO(param):: {
    rules: sloFromRecordingRules('errors', param),
  },

  availabilitySLO(latencySLORules, errorsSLORules):: {
    local latencyLength = std.length(latencySLORules),
    local errorsLength = std.length(errorsSLORules),
    assert latencyLength == errorsLength :
           error 'Non-matching length for input arrays. %d != %d' % [latencyLength, errorsLength],

    rules: [
      {
        record: 'component:availability:slo_ok_%s' % latencySLORules[i].rate,
        expr: '%s * %s' % [latencySLORules[i].record, errorsSLORules[i].record],
        labels: latencySLORules[i].labels,
      }
      for i in std.range(0, std.length(latencySLORules) - 1)

    ],
  },
}
