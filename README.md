# gitops-library
This Repo is meant to store useful application and config example references for deploying Solo products, example applications, and related config

## Table of Contents
- argo-rollouts
- argocd
- bombardier-loadgen
- bookinfo
- cert-manager
- gloo-edge
- gloo-mesh
- gloo-portal
- helloworld
- homer-portal
- httpbin
- istio
- keycloak
- petstore
- solowallet

## Repo Structure
Each application example is broken down into two directories: `deploy` for the application deployments and `config-examples` which provide examples for edge, mesh, or portal configuration examples for the respective app. Where possible, deployment options using ArgoCD as well as the direct YAML manifests are provided

## Getting Started

### Prerequisites
- Kubernetes cluster up and authenticated to kubectl

## Install ArgoCD
```
cd argocd/deploy
./install-argocd.sh
```

### input options
You can provide the inputs below to specify a configuration of argocd
```
./install-argocd.sh {SECURITY} {CONTEXT}
```

SECURITY options: `default`/`insecure`
- If undefined, the install will use the default install of argocd
- `insecure` option allows us to terminate TLS at the edge, and expose argocd using a VirtualService instead of port-forward commands

### access argoCD UI
using port forward, access argocd at localhost:8080 if using the `default` or `insecure` overlay; localhost:8080/argo if using the `insecure-rootpath` overlay
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Username: admin
Password: solo.io

### Next Steps
Once ArgoCD is deployed, feel free to navigate around the example deployments and their respective Gloo Edge / Gloo Mesh / Gloo Portal configurations. Where it makes sense, there are Argo Applications as well as direct YAML manifests for the deployment examples