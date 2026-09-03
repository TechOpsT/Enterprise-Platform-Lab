# Demo walkthrough

1. Run `make status` and show both Argo CD applications healthy.
2. Open `platform.local` and `transformation.local` to show the two workloads on the shared cluster.
3. Open Grafana and show API request rate, latency, structured logs, and namespace filtering.
4. Apply `platform/kyverno/test/noncompliant-pod.yaml` and show Kyverno rejecting it.
5. Show the `platform-daily` Velero schedule and the latest completed backup.
6. Walk through `docs/evidence/policy-backup-recovery-validation.md` and show the isolated restored namespace.
7. Make a small application change, then follow the image publish, GitOps promotion, and Argo CD self-healing path.
8. Finish with `make teardown` in dry discussion only; explain retained PVCs before running any destructive cleanup.
