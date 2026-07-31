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

## Validate the release

```bash
kubectl rollout status deployment/api -n platform-lab
kubectl get hpa,pvc,networkpolicy -n platform-lab
curl -H 'Host: platform.local' http://localhost/api/api/v1/status
```

## Cleanup

`make undeploy` removes the Helm release. `make delete-cluster` removes the entire Kind cluster and its local data.
