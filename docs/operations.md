# Operations guide

## Useful commands

```bash
make status
kubectl logs deploy/api -n platform-lab --tail=100
kubectl describe hpa api -n platform-lab
kubectl top pods -n platform-lab
```

## Generate load and observe HPA

The metrics-server is included by default in Kind. Start a temporary load generator:

```bash
kubectl run load --rm -it --image=busybox:1.36 -n platform-lab -- /bin/sh -c 'while true; do wget -q -O- http://api:8080/api/v1/status >/dev/null; done'
```

In another shell: `kubectl get hpa api -n platform-lab --watch`. If CPU does not rise, increase API CPU work temporarily or reduce the target in a lab-only values override. HPA is based on CPU requests; it will not calculate utilization without them.

## Dashboard starter queries

- Request rate: `sum(rate(platform_api_requests_total[5m]))`
- Error ratio: `sum(rate(platform_api_requests_total{status=~"5.."}[5m])) / sum(rate(platform_api_requests_total[5m]))`
- p95 latency: `histogram_quantile(0.95, sum(rate(platform_api_request_duration_seconds_bucket[5m])) by (le))`
- Pod restarts: `sum(kube_pod_container_status_restarts_total{namespace="platform-lab"}) by (pod)`

Apply the alert rules and ServiceMonitor after the monitoring stack is ready: `kubectl apply -f infra/observability/alerts.yaml && kubectl apply -f infra/observability/platform-api-service-monitor.yaml`.
