# Getting started

## Bootstrap the complete platform

The complete bootstrap needs three local-only credentials. Export them in your shell; they are used to create Kubernetes Secrets and are never written to the repository.

```bash
export POSTGRES_PASSWORD='<strong local password>'
export BACKUP_ACCESS_KEY='<local MinIO access key>'
export BACKUP_SECRET_KEY='<strong local MinIO secret key>'
make bootstrap
make verify
```

This creates the Kind cluster, installs ingress, monitoring, logging, Kyverno, MinIO, Velero, and Argo CD, deploys the platform workload, and registers both GitOps applications. The Kind configuration maps ports 80 and 443 from the control-plane container to your host. Add `127.0.0.1 platform.local transformation.local` to the hosts file, wait for `make status` to show ready pods, then browse to `http://platform.local` and `http://transformation.local`.

The Impact Explorer still needs its database Secret before Argo CD can complete the first sync. Create it from local shell values using the key names documented in that application's Kubernetes runbook.

## Install individual capabilities

If you already have a cluster, each capability can also be installed or upgraded independently:

```bash
make repositories
make observability
make logging
make kyverno
make velero
make argocd
make applications
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Sign into Grafana at `http://localhost:3000` as `admin` with the local-only password in `infra/observability/kube-prometheus-stack-values.yaml`. Never use this credential outside the lab.

## Centralized logging details

`make logging` installs the pinned Loki and Alloy charts. The equivalent commands are:

```bash
helm upgrade --install loki grafana-community/loki \
  --version 18.11.7 \
  --namespace logging \
  --create-namespace \
  --values observability/loki-values.yaml \
  --wait \
  --timeout 10m
```

Install Alloy to collect logs from both application namespaces:

```bash
helm upgrade --install alloy grafana/alloy \
  --version 1.12.1 \
  --namespace logging \
  --values observability/alloy-values.yaml \
  --wait \
  --timeout 10m
```

Apply the provisioned Loki data source to Grafana:

```bash
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 88.2.0 \
  --namespace monitoring \
  --reuse-values \
  --values infra/observability/kube-prometheus-stack-values.yaml \
  --wait \
  --timeout 10m
```

Verify the logging components:

```bash
kubectl get pods,pvc,svc -n logging
helm list -n logging
```

## Validate the release

```bash
kubectl rollout status deployment/api -n platform-lab
kubectl get hpa,pvc,networkpolicy -n platform-lab
curl -H 'Host: platform.local' http://localhost/api/api/v1/status
```

## Cleanup

`make undeploy` removes only the platform workload. The component-specific `*-remove` targets remove logging, monitoring, Kyverno, or Velero. `make teardown` is intentionally informational; run `make delete-cluster` only when you mean to remove the entire Kind cluster and all of its local data.
