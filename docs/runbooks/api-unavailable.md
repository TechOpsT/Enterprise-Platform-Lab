# Runbook: Platform API unavailable

**Alert:** `PlatformAPIHighErrorRate` or failed readiness probes.  
**Severity:** SEV-2 when users cannot use the API; SEV-3 when degraded.

## First five minutes

1. Confirm the user path: `curl -H 'Host: platform.local' http://localhost/api/api/v1/status`.
2. Inspect rollout and pods: `kubectl get deploy,pods -n platform-lab -o wide`.
3. Read recent events and logs:

   ```bash
   kubectl describe deploy/api -n platform-lab
   kubectl logs deploy/api -n platform-lab --tail=100
   kubectl get events -n platform-lab --sort-by=.lastTimestamp
   ```

4. Check whether the fault is ingress-only, API-only, or a dependency problem.

## Diagnosis and response

| Signal | Likely cause | Action |
| --- | --- | --- |
| `ImagePullBackOff` | image/tag unavailable | correct image value; rerun Helm release |
| `CrashLoopBackOff` | application configuration or code fault | inspect previous logs; rollback Helm revision |
| readiness fails | dependency/startup issue | inspect API logs and PostgreSQL/Redis pods |
| no endpoints | selector or readiness mismatch | inspect `kubectl get endpoints api -n platform-lab` |
| ingress responds 404/502 | routing/controller issue | inspect ingress and controller logs |

## Mitigation and recovery

Rollback the last known-good Helm revision: `helm history platform-home-lab -n platform-lab`, then `helm rollback platform-home-lab <REVISION> -n platform-lab`. Verify rollout, endpoint health, request success rate, and that the alert clears.

## Aftercare

Record start/end time, customer impact, detection path, causal change, mitigation, and follow-up owner. Update this runbook if diagnosis required undocumented knowledge.
