# Create KinD Cluster
KIND_CLUSTER_NAME := local-lab
KIND_CONFIG := ./cluster/kind-config.yaml

.PHONY: cluster clean
all: cluster

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
		kubectl apply -f ./cluster/metallb-config.yaml; \
	fi


bootstrap:
# Install K8s gateway API CRDs
	@kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.8.0" | kubectl apply -f -; }
	@kubectl create namespace istio-system
	@kubectl create namespace istio-ingress
	@helm install istio-base istio/base -n istio-system --set defaultRevision=default
	@helm install istiod istio/istiod -n istio-system --wait
	@helm ls -n istio-system




clean:
	@kind delete cluster --name=$(KIND_CLUSTER_NAME)