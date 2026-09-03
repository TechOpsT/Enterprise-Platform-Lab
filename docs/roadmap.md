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

- [x] Add structured request, error, and lifecycle logging to the Flask API.
- [x] Create a Grafana logs dashboard filtered by namespace, application, container, pod, and log level.
- [ ] Link API error-rate or latency panels to the corresponding Loki logs.
- [x] Capture centralized-logging validation in `docs/evidence/`.

### Reliability exercises

- [ ] Delete an API pod and record detection and recovery time.
- [ ] Scale PostgreSQL down as a controlled outage and recover it without deleting the PVC.
- [x] Generate load and capture HPA scaling behavior.
- [ ] Capture an Alertmanager rule firing and resolving.
- [ ] Write short incident reports describing symptoms, response, recovery, and follow-up actions.

### Security and software supply chain

- [x] Add Trivy image scanning to CI with an explicit severity policy.
- [x] Generate SBOM artifacts for the API and frontend images.
- [x] Replace the plaintext development database password with a generated, local-only Kubernetes Secret workflow.
- [x] Install Kyverno as a version-pinned, platform-owned capability managed through GitOps.
- [x] Add Kyverno policies for non-root execution, resource requests and limits, approved image registries, and non-floating image references.
- [x] Validate enrolled workloads through policy reports before enforcing the baseline; keep exceptions under platform ownership.
- [x] Capture evidence of compliant workloads and a noncompliant workload being rejected.

### Backup and disaster recovery

- [x] Define recovery-point and recovery-time objectives, retention, encryption expectations, and restore ownership for platform and application data.
- [x] Install Velero as a version-pinned, platform-owned capability managed through GitOps, using a documented backup target and credential-management pattern.
- [x] Create scheduled backups for Kubernetes resources with explicit namespace and resource inclusion/exclusion rules.
- [x] Add database-native PostgreSQL backups that stream directly to object storage.
- [x] Perform and document a restore into an isolated namespace, validate application and data integrity, and record achieved RPO/RTO.
- [x] Add backup freshness and failure checks to platform alerting.

### Reproducibility and lifecycle operations

- [x] Add Make targets to install, verify, upgrade, and remove Loki and Alloy.
- [x] Pin the kube-prometheus-stack chart version in the Makefile.
- [x] Add a single documented bootstrap workflow for the complete platform.
- [x] Add a clean teardown workflow that accounts for retained logging PVCs.
- [ ] Validate a full rebuild from an empty Kind cluster.

### Portfolio finish

- [x] Link all evidence documents from the README.
- [ ] Capture screenshots of Grafana metrics and logs, Alertmanager state, Argo CD synchronization, and successful CI runs.
- [x] Add a concise demo script covering deployment, GitOps promotion, observability, scaling, self-healing, and recovery.
- [x] Review documentation and user-facing text for naming, spelling, and consistency.

## Definition of done

The lab is portfolio-ready when another engineer can bootstrap it from the repository, deploy a change through CI/CD and Argo CD, inspect metrics and logs, observe an alert, demonstrate scaling and self-healing, verify Kyverno admission enforcement, restore a Velero backup with validated application data, complete one controlled recovery exercise, and tear the environment down using only documented procedures.
