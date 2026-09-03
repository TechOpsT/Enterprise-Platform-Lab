SHELL := /bin/bash
CLUSTER ?= platform-lab
NAMESPACE ?= platform-lab
RELEASE ?= platform-home-lab

PROMETHEUS_CHART_VERSION := 88.2.0
LOKI_CHART_VERSION := 18.11.7
ALLOY_CHART_VERSION := 1.12.1
KYVERNO_CHART_VERSION := 3.7.0
VELERO_CHART_VERSION := 12.1.0
ARGOCD_CHART_VERSION := 8.5.8

.PHONY: cluster delete-cluster repositories ingress load-api load-web platform-secrets deploy undeploy observability observability-remove logging logging-verify logging-remove kyverno kyverno-verify kyverno-remove backup-store velero velero-verify velero-remove argocd applications bootstrap verify teardown test lint status

cluster:
	kind create cluster --name $(CLUSTER) --config infra/kind/kind-config.yaml

delete-cluster:
	kind delete cluster --name $(CLUSTER)

repositories:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
	helm repo add grafana-community https://grafana-community.github.io/helm-charts --force-update
	helm repo add grafana https://grafana.github.io/helm-charts --force-update
	helm repo add kyverno https://kyverno.github.io/kyverno/ --force-update
	helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts --force-update
	helm repo add argo https://argoproj.github.io/argo-helm --force-update
	helm repo update

ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

load-api:
	docker build -t platform-api:dev apps/api
	kind load docker-image platform-api:dev --name $(CLUSTER)

load-web:
	docker build -t platform-web:dev apps/frontend
	kind load docker-image platform-web:dev --name $(CLUSTER)

platform-secrets:
	@test -n "$$POSTGRES_PASSWORD" || (echo "POSTGRES_PASSWORD is required" && exit 1)
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n $(NAMESPACE) create secret generic postgres-credentials --from-literal=POSTGRES_DB=platform --from-literal=POSTGRES_USER=platform --from-literal=POSTGRES_PASSWORD="$$POSTGRES_PASSWORD" --dry-run=client -o yaml | kubectl apply -f -

deploy:
	helm upgrade --install $(RELEASE) charts/platform-home-lab --namespace $(NAMESPACE) --create-namespace --set api.image.repository=platform-api --set api.image.tag=dev --set frontend.image.repository=platform-web --set frontend.image.tag=dev --set api.image.pullPolicy=Never --set frontend.image.pullPolicy=Never --wait --timeout 10m

undeploy:
	helm uninstall $(RELEASE) --namespace $(NAMESPACE)

observability:
	helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version $(PROMETHEUS_CHART_VERSION) --namespace monitoring --create-namespace -f infra/observability/kube-prometheus-stack-values.yaml --wait --timeout 15m
	kubectl apply -f infra/observability/alerts.yaml
	kubectl apply -f infra/observability/platform-api-service-monitor.yaml
	kubectl -n monitoring create configmap platform-logs-dashboard --from-file=platform-logs.json=infra/observability/dashboards/platform-logs.json --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n monitoring label configmap platform-logs-dashboard grafana_dashboard=1 --overwrite

observability-remove:
	helm uninstall kube-prometheus-stack --namespace monitoring

logging:
	helm upgrade --install loki grafana-community/loki --version $(LOKI_CHART_VERSION) --namespace logging --create-namespace --values observability/loki-values.yaml --wait --timeout 10m
	helm upgrade --install alloy grafana/alloy --version $(ALLOY_CHART_VERSION) --namespace logging --values observability/alloy-values.yaml --wait --timeout 10m

logging-verify:
	kubectl get pods,pvc,svc -n logging
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=loki -n logging --timeout=5m
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=alloy -n logging --timeout=5m

logging-remove:
	helm uninstall alloy --namespace logging
	helm uninstall loki --namespace logging

kyverno:
	helm upgrade --install kyverno kyverno/kyverno --version $(KYVERNO_CHART_VERSION) --namespace kyverno --create-namespace --wait --timeout 10m
	kubectl apply -f platform/kyverno/policies.yaml

kyverno-verify:
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=kyverno -n kyverno --timeout=5m
	@if kubectl apply -f platform/kyverno/test/noncompliant-pod.yaml; then echo "ERROR: Kyverno admitted the noncompliant test pod"; kubectl delete namespace policy-test --ignore-not-found; exit 1; else echo "Kyverno rejected the noncompliant test pod as expected"; kubectl delete namespace policy-test --ignore-not-found; fi

kyverno-remove:
	kubectl delete -f platform/kyverno/policies.yaml --ignore-not-found
	helm uninstall kyverno --namespace kyverno

backup-store:
	@test -n "$$BACKUP_ACCESS_KEY" || (echo "BACKUP_ACCESS_KEY is required" && exit 1)
	@test -n "$$BACKUP_SECRET_KEY" || (echo "BACKUP_SECRET_KEY is required" && exit 1)
	kubectl create namespace backup-system --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n backup-system create secret generic minio-credentials --from-literal=MINIO_ROOT_USER="$$BACKUP_ACCESS_KEY" --from-literal=MINIO_ROOT_PASSWORD="$$BACKUP_SECRET_KEY" --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f platform/backup/minio.yaml
	kubectl rollout status deployment/minio -n backup-system --timeout=5m

velero: backup-store
	kubectl create namespace velero --dry-run=client -o yaml | kubectl apply -f -
	@printf '[default]\naws_access_key_id=%s\naws_secret_access_key=%s\n' "$$BACKUP_ACCESS_KEY" "$$BACKUP_SECRET_KEY" | kubectl -n velero create secret generic velero-object-store-credentials --from-file=cloud=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
	kubectl -n transformation-explorer create secret generic backup-object-store-credentials --from-literal=MINIO_ROOT_USER="$$BACKUP_ACCESS_KEY" --from-literal=MINIO_ROOT_PASSWORD="$$BACKUP_SECRET_KEY" --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install velero vmware-tanzu/velero --version $(VELERO_CHART_VERSION) --namespace velero --values platform/velero/values.yaml --wait --timeout 10m
	kubectl apply -f platform/backup/transformation-postgres-backup.yaml
	kubectl apply -f platform/velero/schedules.yaml

velero-verify:
	kubectl rollout status deployment/velero -n velero --timeout=5m
	kubectl rollout status daemonset/node-agent -n velero --timeout=5m
	kubectl get backupstoragelocation,schedule -n velero

velero-remove:
	helm uninstall velero --namespace velero

argocd:
	helm upgrade --install argo-cd argo/argo-cd --version $(ARGOCD_CHART_VERSION) --namespace argocd --create-namespace --wait --timeout 15m

applications:
	kubectl apply -f gitops/applications/kyverno.yaml
	kubectl apply -f gitops/applications/platform-policies.yaml
	kubectl apply -f gitops/applications/velero.yaml
	kubectl apply -f gitops/applications/data-protection.yaml
	kubectl apply -f gitops/applications/platform-home-lab.yaml
	kubectl apply -f gitops/applications/transformation-explorer.yaml

bootstrap: cluster repositories ingress load-api load-web platform-secrets observability logging kyverno velero argocd deploy applications

verify: lint logging-verify kyverno-verify velero-verify status

teardown:
	-kubectl delete -f gitops/applications/transformation-explorer.yaml
	-kubectl delete -f gitops/applications/data-protection.yaml
	-kubectl delete -f gitops/applications/platform-policies.yaml
	-kubectl delete -f gitops/applications/velero.yaml
	-kubectl delete -f gitops/applications/kyverno.yaml
	-helm uninstall velero --namespace velero
	-helm uninstall kyverno --namespace kyverno
	-helm uninstall alloy --namespace logging
	-helm uninstall loki --namespace logging
	-helm uninstall kube-prometheus-stack --namespace monitoring
	-helm uninstall $(RELEASE) --namespace $(NAMESPACE)
	@echo "Retained PVCs are listed below. Review them before deleting data. Use 'make delete-cluster' only when complete cluster-data removal is intended."
	-kubectl get pvc -A

test:
	cd apps/api && python -m pytest

lint:
	helm lint charts/platform-home-lab
	helm template platform-home-lab charts/platform-home-lab >/dev/null

status:
	kubectl get pods,svc,ingress,hpa,pvc -n $(NAMESPACE)
	kubectl get applications -n argocd
