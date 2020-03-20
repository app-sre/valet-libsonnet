local slo = import '../lib/valet.libsonnet';

// Rules that will be reused in SLO rules
local labels = ['service="cincinnati"', 'component="cincinnati-policy-engine"'];
local httpRates = slo.httpRates({
  metric: 'haproxy_server_http_responses_total',
  recordingRuleMetric: 'http_responses_total',
  selectors: ['route="cincinnati-route-prod"'],
  labels: labels,
});
local latencyPercentileRates = slo.latencyPercentileRates({
  metric: 'cincinnati_pe_v1_graph_serve_duration_seconds_bucket',
  percentile: 90,
  selectors: ['job="cincinnati-policy-engine"'],
  labels: labels,
});

// SLOs from above rules (they will inherit the labels)
local volumeSLO = slo.volumeSLO({
  recordingRules: httpRates.rateRules,
  threshold: 5000,
  selectors: ['route="cincinnati-route-prod"', 'status_class!="5xx"'],
});
local latencySLO = slo.latencySLO({
  recordingRules: latencyPercentileRates.rules,
  threshold: 3,
});
local errorsSLO = slo.errorsSLO({
  recordingRules: httpRates.errorRateRules,
  threshold: 1,
  selectors: ['route="cincinnati-route-prod"'],
});
local availabilitySLO = slo.availabilitySLO(latencySLO.rules, errorsSLO.rules);

{
  recordingrule:
    httpRates.rateRules +
    httpRates.errorRateRules +
    latencyPercentileRates.rules +
    volumeSLO.rules +
    latencySLO.rules +
    errorsSLO.rules +
    availabilitySLO.rules,
}
