# gitops-library
 
Disclaimer: This is a work in progress. Blog to likely follow, so stay tuned :)

Not officially supported by Solo.io. 

## Kustomize Structure
This repo is structured using kustomize bases and overlays to foster re-use of configuration where possible. 

### overlay
Overlays do exactly as the name, and layer over base manifests and can additionally provide configuration that can be specific to the cluster using kustomize. A few examples of kustomize options would be adding `secrets` and `configMaps` using the `configMapGenerator` and `secretGenerators` built into kustomize. Another being leveraging the `patchesStrategicMerge` or `patchesJson6902` features which can be pretty powerful.

 An few examples of how overlays can be useful:
- reuse base manifest(s) but create overlays for prod, staging, dev, test
- reuse an existing overlay but create different `configmaps`, `secrets`, `labels`
- reuse an existing overlay but patch/add more configuration (i.e. Cloud to On-Prem/OpenShift environments)
- create overlays to organize multi-cloud or multi-cluster configuration

### base
base manifests are organized here. All overlay layers should inherit their configuration from the base manifests. Leave out instance-specific or environment-specific config out of the base manifests such as namespaces as these will be added/patched using overlays.

## Table of Contents - Labs
- [installing argocd](https://github.com/solo-io/gitops-library/tree/main/argocd)
- [installing gloo-edge](https://github.com/solo-io/gitops-library/tree/main/gloo-edge)
  - [configuring gloo-fed](https://github.com/solo-io/gitops-library/tree/main/gloo-edge#configuring-gloo-fed)
  - [deploy and configure keycloak](https://github.com/solo-io/gitops-library/tree/main/keycloak)
  - [deploy hipstershop and expose with gloo-edge](https://github.com/solo-io/gitops-library/tree/main/hipstershop#hipstershop-gloo-edge-demo)
  - [walkthrough bookinfo gloo-edge features demo](https://github.com/solo-io/gitops-library/tree/main/bookinfo#bookinfo-gloo-edge-demo)
- [installing gloo-mesh](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh)
  - [register cluster to gloo-mesh using meshctl](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh#register-cluster-using-meshctl)
- [installing istio](https://github.com/solo-io/gitops-library/tree/main/istio)
  - [installing istio-addons](https://github.com/solo-io/gitops-library/tree/main/istio#install-istio-addons)
  - [deploy hipstershop istio demo app](https://github.com/solo-io/gitops-library/tree/main/hipstershop#hipstershop-istio-demo)
- [installing gloo-portal](https://github.com/solo-io/gitops-library/tree/main/gloo-portal)
  - [deploying gloo-portal petstore demo](https://github.com/solo-io/gitops-library/tree/main/petstore)
- [Installing argo workflows](./argo-workflows/README.md)