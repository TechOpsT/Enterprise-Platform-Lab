# Roadmap

## Completed baseline

- [x] Reproducible Kind cluster and NGINX ingress workflow
- [x] React, Flask, Redis, and PostgreSQL deployment through Helm
- [x] Health probes, resources, HPA, PVC, RBAC, Pod Security labels, and network policies
- [x] Prometheus-format application metrics, alert definitions, Grafana/Prometheus installation guide
- [x] GitHub Actions validation/build workflow
- [x] SLOs, error-budget policy, and initial incident runbooks

## Next increments

### GitOps — Argo CD

- Install Argo CD in a separate `argocd` namespace.
- Create an `Application` pointing to this chart and a `values/local.yaml` file.
- Enable automated sync with self-heal; demonstrate and document drift correction.

### Logs — Loki

- Install Loki and Promtail (or Grafana Alloy).
- Add a log dashboard filtered by namespace/app label.
- Link Grafana panels from an error-rate spike to API logs.

### Reliability exercises

- Delete an API pod and capture detection/recovery time.
- Scale PostgreSQL down as a controlled outage; practice recovery without PVC deletion.
- Generate load; capture HPA timing and resource saturation.
- Write short incident reports with what changed afterward.

### Security and supply chain

- Add Trivy image scanning and SBOM output to CI.
- Replace Helm plaintext development secret with External Secrets/Vault pattern.
- Add Kyverno/Gatekeeper policy checks.

## Evidence to retain for your portfolio

Screenshots of Grafana dashboards and HPA scaling, CI pass links, alert firing/resolution evidence, Helm release history, incident reports, and an Argo CD sync/drift demonstration. Link these from the README as you complete each phase.
