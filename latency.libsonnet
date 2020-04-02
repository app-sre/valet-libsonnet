local util = import '_util.libsonnet';
{
  latencyPercentileRates(param):: {
    local slo = {
      metric: error 'must set metric for latency',
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
          std.parseInt(slo.percentile) / 100,
          slo.metric,
          std.join(',', slo.selectors),
          rate,
        ],
        record: 'component:latency:p%s_rate%s' % [
          slo.percentile,
          rate,
        ],
        labels: labels,
        rate:: rate,
      }
      // remove duplicates or it will lead to duplicate rules
      for rate in std.uniq(slo.rates)
    ],
  },
}
