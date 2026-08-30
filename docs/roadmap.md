# Roadmap

## Completed platform baseline

- [x] Reproducible two-node Kind cluster and NGINX ingress workflow
- [x] React frontend and Flask API deployed through Helm
- [x] PostgreSQL persistent storage and Redis integration
- [x] Health probes, resource requests and limits, HPA, RBAC, Pod Security labels, and network policies
- [x] Prometheus application metrics, Grafana dashboard, Alertmanager rules, and ServiceMonitor
- [x] Availability and latency SLOs, error-budget policy, and initial incident runbooks

## Completed delivery and GitOps

- [x] GitHub Actions validation and container build workflow
- [x] API and frontend image publishing to GitHub Container Registry
- [x] Automated image-tag promotion into Helm values
- [x] Argo CD application with automated synchronization, pruning, and self-healing
- [x] End-to-end release validation from source change to the running application
- [x] Argo CD drift and self-healing evidence

## Completed centralized logging

- [x] Single-replica, persistent Loki deployment for the local lab
- [x] Grafana Alloy collection of pod logs from the `platform-lab` namespace
- [x] Kubernetes metadata labels for namespace, pod, and container queries
- [x] Helm-provisioned Loki data source in Grafana
- [x] LogQL validation through Grafana Explore
- [x] Installation, architecture, operations, and troubleshooting documentation

## Next priorities

### Application logging and dashboards

- [ ] Add structured request, error, and lifecycle logging to the Flask API.
- [ ] Create a Grafana logs dashboard filtered by namespace, application, container, pod, and log level.
- [ ] Link API error-rate or latency panels to the corresponding Loki logs.
- [ ] Capture centralized-logging validation in `docs/evidence/`.

### Reliability exercises

- [ ] Delete an API pod and record detection and recovery time.
- [ ] Scale PostgreSQL down as a controlled outage and recover it without deleting the PVC.
- [x] Generate load and capture HPA scaling behavior.
- [ ] Capture an Alertmanager rule firing and resolving.
- [ ] Write short incident reports describing symptoms, response, recovery, and follow-up actions.

### Security and software supply chain

- [ ] Add Trivy image scanning to CI with an explicit severity policy.
- [ ] Generate SBOM artifacts for the API and frontend images.
- [ ] Replace the plaintext development database password with an External Secrets, Sealed Secrets, or equivalent lab pattern.
- [ ] Add Kyverno or Gatekeeper policies for non-root execution, resource limits, and approved image registries.
- [ ] Capture evidence of a noncompliant workload being rejected.

### Reproducibility and lifecycle operations

- [ ] Add Make targets to install, verify, upgrade, and remove Loki and Alloy.
- [ ] Pin the kube-prometheus-stack chart version in the Makefile.
- [ ] Add a single documented bootstrap workflow for the complete platform.
- [ ] Add a clean teardown workflow that accounts for retained logging PVCs.
- [ ] Validate a full rebuild from an empty Kind cluster.

### Portfolio finish

- [ ] Link all evidence documents from the README.
- [ ] Capture screenshots of Grafana metrics and logs, Alertmanager state, Argo CD synchronization, and successful CI runs.
- [ ] Add a concise demo script covering deployment, GitOps promotion, observability, scaling, self-healing, and recovery.
- [ ] Review documentation and user-facing text for naming, spelling, and consistency.

## Definition of done

The lab is portfolio-ready when another engineer can bootstrap it from the repository, deploy a change through CI/CD and Argo CD, inspect metrics and logs, observe an alert, demonstrate scaling and self-healing, complete one controlled recovery exercise, and tear the environment down using only documented procedures.
