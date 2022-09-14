# Installing with Helm

## Gloo Portal
```
helm repo add gloo-portal https://storage.googleapis.com/dev-portal-helm
helm repo update
helm upgrade --install gloo-portal gloo-portal/gloo-portal --namespace gloo-portal --create-namespace --version 1.2.9 --values values.yaml
```

### Uninstall
```
helm uninstall gloo-portal -n gloo-portal
```