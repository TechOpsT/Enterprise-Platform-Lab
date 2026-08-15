# Argo CD Self-Healing Validation

## Objective

Verify that Argo CD detects and corrects configuration drift in the Kubernetes cluster.

## Test Performed

The frontend Deployment was manually deleted from the `platform-lab` namespace:

kubectl delete deployment frontend -n platform-lab

Argo CD automated sync with `selfHeal: true` detected the missing resource and recreated the frontend Deployment from the Git repository.

## Verification

kubectl get deployment frontend -n platform-lab
kubectl get pods -n platform-lab

## Expected Result

The frontend Deployment returns automatically.
Frontend pod(s) return to Running.
The Argo CD application returns to Synced and Healthy.
The application remains reachable at http://platform.local.

## Outcome

Argo CD self-healing was successfully validated. Git remains the source of truth for the platform workload configuration.