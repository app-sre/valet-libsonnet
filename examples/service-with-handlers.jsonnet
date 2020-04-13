local slo = import '../valet.libsonnet';

// Rules that will be reused in SLO rules
local labels = ['service="yolo"', 'component="yak-shaver"'];
local rates = ['5m'];
local httpRatesRead = slo.httpRates({
  metric: 'haproxy_server_http_responses_total',
  selectors: ['route="yak-shaver-read"'],
  rates: rates,
  labels: labels,
});
local httpRatesWrite = slo.httpRates({
  metric: 'haproxy_server_http_responses_total',
  selectors: ['route="yak-shaver-write"'],
  rates: rates,
  labels: labels,
});

local latencyPercentileRatesRead = slo.latencyPercentileRates({
  metric: 'http_request_duration_seconds_bucket',
  selectors: ['job="yak-shaver-read"'],
  percentile: '95',
  labels: labels,
  rates: rates,
});
local latencyPercentileRatesWrite = slo.latencyPercentileRates({
  metric: 'http_request_duration_seconds_bucket',
  selectors: ['job="yak-shaver-write"'],
  percentile: '95',
  labels: labels,
  rates: rates,
});

local volumeSLORead = slo.volumeSLO({
  rules: httpRatesRead.rateRules,
  threshold: 1000,
});
local volumeSLOWrite = slo.volumeSLO({
  rules: httpRatesWrite.rateRules,
  threshold: 200,
});
local latencySLORead = slo.latencySLO({
  rules: latencyPercentileRatesRead.rules,
  threshold: '0.5',
});
local latencySLOWrite = slo.latencySLO({
  rules: latencyPercentileRatesWrite.rules,
  threshold: '1',
});
local errorsSLORead = slo.errorsSLO({
  rules: httpRatesRead.errorRateRules,
  threshold: '1',
});
local errorsSLOWrite = slo.errorsSLO({
  rules: httpRatesWrite.errorRateRules,
  threshold: '5',
});

local availabilitySLORead = slo.availabilitySLO({
  latencyRules: [latencySLORead.rules],
  errorsRules: [errorsSLORead.rules],
});
local availabilitySLOWrite = slo.availabilitySLO({
  latencyRules: [latencySLOWrite.rules],
  errorsRules: [errorsSLOWrite.rules],
});

// We don't support for the moment availaility SLO as a product
// of other availability SLOs, but this is easy to overcome
local availabilitySLO = slo.availabilitySLO({
  latencyRules: [latencySLORead.rules] + [latencySLOWrite.rules],
  errorsRules: [errorsSLORead.rules] + [errorsSLOWrite.rules],
  // let's add one label that differentiate this from the rest as
  // handler selectors won't get in the selectors. We could also
  // do it querying through handler="" although I guess this is
  // clearer
  labels: ['route="YAK-SHAVER-ALL"', 'job="YAK-SHAVER-ALL"'],
});

{
  recordingrule:
    httpRatesRead.rateRules +
    httpRatesWrite.rateRules +
    httpRatesRead.errorRateRules +
    httpRatesWrite.errorRateRules +
    latencyPercentileRatesRead.rules +
    latencyPercentileRatesWrite.rules +
    volumeSLORead.rules +
    volumeSLOWrite.rules +
    latencySLORead.rules +
    latencySLOWrite.rules +
    errorsSLORead.rules +
    errorsSLOWrite.rules +
    availabilitySLORead.rules +
    availabilitySLOWrite.rules +
    availabilitySLO.rules,
}
