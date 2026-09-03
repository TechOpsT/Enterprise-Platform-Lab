# Policy, backup, and recovery validation

Date: 2026-09-02 (America/Chicago)

## Environment

- Kind cluster: `kind-platform-lab`
- Kubernetes: v1.35.0, two Ready nodes
- Kyverno chart 3.7.0 / Kyverno v1.17.0
- Velero chart 12.1.0 / Velero v1.18.1
- AWS object-store plugin v1.14.2
- Local S3-compatible target: MinIO

## Kyverno

The platform baseline was installed in enforcement mode for namespaces carrying `platform.techopst.dev/policy-tier=restricted`. Existing `platform-lab` and `transformation-explorer` workloads produced policy reports with five passes and no failures per pod.

The test manifest at `platform/kyverno/test/noncompliant-pod.yaml` was rejected. Kyverno reported failures for the floating image tag, unapproved registry, missing CPU and memory requests/limits, missing restricted container security context, and missing pod-level non-root/seccomp settings.

## Centralized logging

Alloy was upgraded with discovery enabled for both `platform-lab` and `transformation-explorer`. A direct Loki query for `{namespace="transformation-explorer"}` returned HTTP 200 and a structured assessment-service health event with namespace, application, container, pod, service, severity, route, response status, and duration fields. The `Platform Application Logs` Grafana dashboard provides namespace, application, container, pod, and level filters.

## Backup

The `default` Velero BackupStorageLocation reported `Available`. The first namespace smoke backup completed, but the restore drill showed that Kind local-path PVCs are exposed as `hostPath` volumes and are skipped by Velero's filesystem backup. This result confirmed that a raw volume backup could not be the PostgreSQL recovery plan.

The corrected database backup uses `pg_dump` and uploads a custom-format dump directly to a dedicated MinIO bucket. The smoke Job uploaded both a timestamped object and `postgres-backups/transformation/latest.dump`; the dump size was 9.74 KiB. Keeping database objects outside Velero's own bucket is required because Velero rejects unknown top-level directories. No credential value was written to the repository or captured in command output.

## Restore

Velero restored the Kubernetes resources into the isolated `transformation-explorer-restore` namespace. The logical restore Job downloaded `latest.dump` from MinIO and restored it with ownership and grants intact. Validation found all four expected application tables:

- `assessment.alembic_version`
- `assessment.assessments`
- `content.alembic_version`
- `content.definitions`

After restarting the two database-dependent Deployments, content and assessment reached Ready. PostgreSQL, Redis, recommendation, and web were also Ready. The drill completed well inside the 60-minute RTO, and the source dump was less than one hour old, inside the 24-hour RPO.

## Application onboarding

Argo CD reported the `transformation-explorer` application `Synced` and `Healthy`. The PostgreSQL StatefulSet ignores only `/spec/volumeClaimTemplates`, whose API-defaulted immutable fields otherwise create persistent false drift. After reloading the current web image, an ingress request with `Host: transformation.local` returned HTTP 200.

## Follow-up

The local MinIO PVC shares the Kind cluster's failure domain. For a non-lab deployment, move the backup location to external object storage with server-side encryption and independent credentials.
