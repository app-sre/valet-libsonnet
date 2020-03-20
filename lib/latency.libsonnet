local util = import '_util.libsonnet';
{
  latencyPercentileRates(param):: {
    local slo = {
      metric: error 'must set metric for latency',
      recordingRuleMetric: self.metric,
      selectors: error 'must set selectors for latency',
      labels: [],
      rates: ['5m', '30m', '1h', '2h', '6h', '1d'],
      percentile: error 'must set percentile for latency',
    } + param,

    local labels =
      util.selectorsToLabels(slo.selectors) +
      util.selectorsToLabels(slo.labels),

    rules: [
      {
        expr: |||
          histogram_quantile(
            %.2f,
            sum(rate(%s{%s}[%s])) by (le)
          )
        ||| % [
          slo.percentile / 100,
          slo.metric,
          std.join(',', slo.selectors),
          rate,
        ],
        record: 'component:%s:p%s_rate%s' % [
          slo.recordingRuleMetric,
          slo.percentile,
          rate,
        ],
        labels: labels,
        rate:: rate,
      }
      for rate in slo.rates
    ],
  },
}
