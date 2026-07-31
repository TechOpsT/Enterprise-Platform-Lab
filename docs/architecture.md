# Architecture and engineering decisions

The chart keeps all components in the `platform-lab` namespace: React frontend, Flask API, PostgreSQL, and Redis. Ingress is the only intended entry path. API exposes `/metrics` in Prometheus format and uses live/ready endpoints for Kubernetes probes.

| Decision | Why it exists | Lab trade-off |
| --- | --- | --- |
| Kind with host mappings | repeatable, zero-cloud-cost ingress testing | single-node failure domains are not realistic |
| Helm chart | reusable, versioned installation contract | chart is intentionally compact instead of fully modular |
| PostgreSQL StatefulSet + PVC | stateful storage mechanics are visible | credentials are local values only |
| Default-deny network policy | makes allowed paths explicit | policy support requires a CNI that enforces it |
| `restricted` pod-security namespace | demonstrates a safe workload baseline | test each third-party image for compatibility |
| kube-prometheus-stack | includes Prometheus, Grafana, Alertmanager, node and cluster metrics | consumes significant local resources |

## Data and traffic paths

1. Browser requests land at NGINX ingress on `platform.local`.
2. `/` goes to the frontend; `/api` goes to Flask.
3. Flask is permitted to reach PostgreSQL and Redis by its network policy.
4. Prometheus scrapes Flask metrics; Grafana queries Prometheus; Alertmanager receives rule evaluations.

## Production gaps to close deliberately

TLS/cert-manager, a real container registry, external secrets, backup/restore, multi-node testing, persistent Redis, and image scanning are intentionally roadmap work—not claims this local baseline makes.
