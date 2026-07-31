SHELL := /bin/bash
CLUSTER ?= platform-lab
NAMESPACE ?= platform-lab
RELEASE ?= platform-home-lab

.PHONY: cluster delete-cluster ingress deploy undeploy observability test lint load-api load-web status

cluster:
	kind create cluster --name $(CLUSTER) --config infra/kind/kind-config.yaml

delete-cluster:
	kind delete cluster --name $(CLUSTER)

ingress:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s

load-api:
	docker build -t platform-api:dev apps/api
	kind load docker-image platform-api:dev --name $(CLUSTER)

load-web:
	docker build -t platform-web:dev apps/frontend
	kind load docker-image platform-web:dev --name $(CLUSTER)

deploy:
	helm upgrade --install $(RELEASE) charts/platform-home-lab --namespace $(NAMESPACE) --create-namespace --set api.image.repository=platform-api --set api.image.tag=dev --set frontend.image.repository=platform-web --set frontend.image.tag=dev --set api.image.pullPolicy=Never --set frontend.image.pullPolicy=Never

undeploy:
	helm uninstall $(RELEASE) --namespace $(NAMESPACE)

observability:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace -f infra/observability/kube-prometheus-stack-values.yaml

test:
	cd apps/api && python -m pytest

lint:
	helm lint charts/platform-home-lab

status:
	kubectl get pods,svc,ingress,hpa,pvc -n $(NAMESPACE)
