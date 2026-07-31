# Runbook: PostgreSQL unavailable

## Detect

Look for PostgreSQL pods not ready, failed storage attachment, API dependency errors, or elevated API errors.

```bash
kubectl get pods,pvc -n platform-lab -l app=postgres
kubectl describe pod postgres-0 -n platform-lab
kubectl logs postgres-0 -n platform-lab --tail=100
```

## Diagnose

- A `Pending` PVC usually means no matching storage class or provisioner.
- A `CrashLoopBackOff` can be an invalid secret, data permission issue, or corrupt local data.
- Do not delete the PVC during an incident—it is the only lab persistence layer.

## Mitigate

Restore a known-good configuration or roll back the chart. For a deliberately disposable local reset only, document the data loss, uninstall the release, delete the specific PostgreSQL PVC after confirming its name, then reinstall. Production recovery requires tested backups; add Velero/database backups before treating this as production-like.
