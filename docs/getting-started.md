# Getting started

## Create the local cluster

From the repository root, run:

```bash
make cluster
make ingress
make load-api load-web
make deploy
```

The Kind configuration maps ports 80 and 443 from the control-plane container to your host. Add `127.0.0.1 platform.local` to the hosts file, wait for `make status` to show ready pods, then browse to `http://platform.local`.

## Install observability

```bash
make observability
kubectl apply -f infra/observability/alerts.yaml
kubectl apply -f infra/observability/platform-api-service-monitor.yaml
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

Sign into Grafana at `http://localhost:3000` as `admin` with the local-only password in `infra/observability/kube-prometheus-stack-values.yaml`. Never use this credential outside the lab.

## Install centralized logging

Install the pinned monolithic Loki release:

```bash
helm upgrade --install loki grafana-community/loki \
  --version 18.11.7 \
  --namespace logging \
  --create-namespace \
  --values observability/loki-values.yaml \
  --wait \
  --timeout 10m
```

Install Alloy to collect logs from the `platform-lab` namespace:

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

`make undeploy` removes the Helm release. `make delete-cluster` removes the entire Kind cluster and its local data.
