# Create KinD Cluster
KIND_CLUSTER_NAME := local-lab
KIND_CONFIG := ./cluster/kind-config.yaml

.PHONY: clean cluster ingress mockserver istio
all: cluster

clean:
	@kind delete cluster --name=$(KIND_CLUSTER_NAME)

cluster: 
# Check if KinD is installed, if not install it
ifeq (, $(shell which kind))
	@echo "KinD not found, installing it now."
	@curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
	@chmod +x ./kind
	@sudo mv ./kind /usr/local/bin/kind
endif
# Check if a cluster already exists, if not create else skip
# Also creates a Metal LB deployment to enable LoadBalancer services - TODO dynamically set IP range from `docker network inspect -f '{{.IPAM.Config}}' kind`
	@if kind get clusters | grep -qx "$(KIND_CLUSTER_NAME)"; then \
		echo "Cluster already exists, skipping creation..." ; \
	else \
		kind create cluster --config=$(KIND_CONFIG) --name=$(KIND_CLUSTER_NAME); \
		kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml; \
		kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s; \
		./cluster/cluster-config.sh; \
		kubectl apply -f ./cluster/metallb-config.yaml; \
	fi

ingress:
# Install K8s gateway API CRDs
	@kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.8.0" | kubectl apply -f -; }
	@kubectl create namespace ingress

mockserver:
	@kubectl create namespace mockserver
	@kubectl -n mockserver apply -f ./mockserver/configmap.yaml
	@helm upgrade --install --namespace mockserver --version 5.14.0 mockserver mockserver/mockserver

servicemesh:
	@kubectl create namespace istio-system
	@helm upgrade --install -namespace istio-system istio-base istio/base --set defaultRevision=default
	@helm upgrade --install -namespace istio-system istiod istio/istiod --wait
	@helm ls -n istio-system




