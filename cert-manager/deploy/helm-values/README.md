# Installing with Helm

## Cert Manager
```
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install jetstack jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.2 --set-string installCRDs=true
```

### Uninstall
```
helm uninstall jetstack -n cert-manager
```