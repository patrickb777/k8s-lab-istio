# Create KinD Cluster
KIND_CLUSTER_NAME := local-lab
KIND_CONFIG := ./cluster/kind-config.yaml

.PHONY: clean cluster ingress mockserver servicemesh
all: cluster servicemesh ingress mockserver

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
# Also creates a Metal LB deployment to enable LoadBalancer services
	@if kind get clusters | grep -qx "$(KIND_CLUSTER_NAME)"; then \
		echo "Cluster already exists, skipping creation..." ; \
	else \
		kind create cluster --config=$(KIND_CONFIG) --name=$(KIND_CLUSTER_NAME); \
		kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml; \
		kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s; \
		./cluster/cluster-config.sh; \
		kubectl apply -f ./cluster/metallb-config.yaml; \
	fi

servicemesh:
	@kubectl create namespace istio-system
	@helm repo add istio https://istio-release.storage.googleapis.com/charts
	@helm repo update
	@helm upgrade --install --namespace istio-system istiobase istio/base --set defaultRevision=default
	@helm upgrade --install --namespace istio-system istiod istio/istiod --wait

ingress:
# Install K8s gateway API CRDs
	@kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.1/standard-install.yaml
	@kubectl wait --namespace=gateway-system --for=condition=Ready pod -l name=gateway-api-admission-server
	@kubectl create namespace ingress
	@kubectl --namespace ingress apply -f ./ingress/external-gateway.yaml

mockserver:
	@kubectl create namespace mockserver
# label the namespace to instruct Istio to automatically inject Envoy sidecar proxies and allow cross namespace routing
	@kubectl label namespace mockserver istio-injection=enabled
	@kubectl label namespace mockserver istio-shared-gateway-access=true
	@kubectl --namespace mockserver apply -f ./mockserver/configmap.yaml
	@helm upgrade --install --namespace mockserver --version 5.14.0 mockserver mockserver/mockserver
	@kubectl --namespace mockserver apply -f ./mockserver/HTTProute.yaml
