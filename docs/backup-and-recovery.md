# Backup and recovery

This lab uses two layers of protection because a Kubernetes backup and a database backup solve different problems.

- Velero captures Kubernetes resources and mounted volume data for the `platform-lab` and `transformation-explorer` namespaces.
- PostgreSQL-native logical backups stream directly to MinIO and provide an application-consistent recovery path for database records.

## Recovery objectives

| Objective | Lab target |
| --- | --- |
| Recovery point (RPO) | No more than 24 hours of data loss |
| Recovery time (RTO) | Restore service within 60 minutes |
| Retention | Seven daily Velero recovery points |
| Backup owner | Platform operator |
| Restore approval | Project owner |

MinIO is the local S3-compatible backup target. Its PVC is useful for practicing workload restores, but it lives inside the same Kind cluster and therefore does not protect against deleting the whole cluster. Kind's local-path volumes appear as `hostPath` volumes and are not supported by Velero filesystem backup, which is another reason the PostgreSQL dump goes directly to object storage. A production design would use an object store outside the failure domain and enable server-side encryption.

## Restore drill

1. Confirm the latest schedule is complete with `kubectl get backups -n velero`.
2. Record the backup timestamp and begin the recovery timer.
3. Apply `platform/velero/smoke-restore.yaml` to restore Kubernetes resources into `transformation-explorer-restore`.
4. Wait for completion and inspect `velero restore describe <restore-name> --details`.
5. Copy the scoped object-store Secret into the isolated namespace, apply `platform/backup/transformation-postgres-restore-job.yaml`, and wait for the Job to complete.
6. Validate the restored Deployments, Services, PVCs, PostgreSQL tables, and application readiness.
7. Record the achieved RPO and RTO in `docs/evidence/`.

Never restore over the active namespace during a drill. Treat a production restore as a controlled change with an owner, rollback plan, and explicit approval.
