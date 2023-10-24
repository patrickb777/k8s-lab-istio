# Mockserver

1. Apply configmap.yaml to the `mockserver` namespace
2. Install via Helm 
```helm upgrade --install --namespace mockserver --create-namespace --version 5.14.0 mockserver mockserver/mockserver```
3. If wanting to use LoadBalancer svc delete existing svc and apply service.yaml to the mockserver namespace