# GHCR and Argo CD Release Validation

## Objective

Validate the delivery path from a Git commit to a running Kubernetes workload.

## Release Flow

1. A commit was pushed to the `main` branch.
2. GitHub Actions built the API and frontend container images.
3. GitHub Actions published immutable images to GitHub Container Registry (GHCR).
4. Argo CD was configured to deploy the commit-specific image tag.
5. Kubernetes pulled the images from GHCR and performed a rolling update.

## Deployed Images

ghcr.io/techopst/platform-api:0051ca974e375a8085547e08abf41246104c35aa
ghcr.io/techopst/platform-web:0051ca974e375a8085547e08abf41246104c35aa

## Verification

kubectl get application platform-home-lab -n argocd
kubectl get deployment api frontend -n platform-lab
kubectl get pods -n platform-lab
Invoke-WebRequest http://platform.local | Select-Object StatusCode

## Expected Result

Argo CD reports the application as Synced and Healthy.
API and frontend pods are Running.
Both workloads use immutable GHCR image tags.
http://platform.local returns HTTP status 200.

## Outcome
The platform successfully deploys versioned container images through GitHub Actions, GitHub Container Registry, Argo CD, and Kubernetes.