# Installing with Helm

## Homer Link Portal
```
helm repo add homer-portal https://k8s-at-home.com/charts/
helm repo update
helm upgrade --install homer k8s-at-home/homer --namespace web-portal --create-namespace --version 7.3.0 --values values.yaml
```

### Uninstall
```
helm uninstall homer -n web-portal
```