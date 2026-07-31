# Service level objectives

These targets apply to the Flask API in the local lab. They are written as real operational contracts, while recognizing that a single-machine Kind environment cannot establish production-grade availability.

| Objective | Target | Indicator | Error budget (30 days) |
| --- | --- | --- | --- |
| Availability | 99.5% successful requests | `1 - (5xx requests / all requests)` | 3h 36m of failed-request time equivalent |
| Latency | 95% under 500 ms | p95 `platform_api_request_duration_seconds` | 5% of requests may exceed target |
| Freshness | 99% ready probes succeed | readiness-probe success rate | 7h 12m of unsuccessful-probe time equivalent |

## PromQL indicators

```promql
# Availability, trailing 30 days
1 - (sum(increase(platform_api_requests_total{status=~"5.."}[30d])) / sum(increase(platform_api_requests_total[30d])))

# p95 latency, trailing 5 minutes
histogram_quantile(0.95, sum(rate(platform_api_request_duration_seconds_bucket[5m])) by (le))
```

## Error-budget policy

- **>50% remaining:** normal feature delivery and planned reliability work.
- **25–50% remaining:** review recent incidents; require a rollback plan for higher-risk changes.
- **<25% remaining:** pause nonessential changes to the API; prioritize reliability fixes.
- **Exhausted:** incident review and recovery work before feature deployment resumes.

For a production service, record these SLOs in a dashboard and page only on a burn-rate alert, not a single transient fault.
