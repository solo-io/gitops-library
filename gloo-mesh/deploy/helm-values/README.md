# Installing with Helm

## Gloo Mesh Enterprise
```
helm repo add gloo-mesh-enterprise https://storage.googleapis.com/gloo-mesh-enterprise/gloo-mesh-enterprise
helm repo update
helm upgrade --install gloo-mesh-enterprise gloo-mesh-enterprise/gloo-mesh-enterprise --namespace gloo-mesh --create-namespace --version 2.1.0-beta25 --set-string licenseKey=$GM_LICENSE_KEY --values values.yaml
```

### Uninstall
```
helm uninstall gloo-mesh-enterprise -n gloo-mesh
```