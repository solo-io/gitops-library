# Installing with Helm

## Gloo Edge Open Source
```
helm repo add gloo https://storage.googleapis.com/solo-public-helm
helm repo update
helm upgrade --install gloo gloo/gloo --namespace gloo-system --create-namespace --version 1.12.16
```

## Gloo Edge Enterprise
```
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
helm repo update
helm upgrade --install gloo glooe/gloo-ee --namespace gloo-system --create-namespace --version 1.12.15 --set-string license_key=$LICENSE_KEY --values values-nofed.yaml
```

### Uninstall
```
helm uninstall gloo -n gloo-system
```