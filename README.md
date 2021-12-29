# gitops-library
 
Disclaimer: This is a work in progress, which means things may change as improvements and additions are made. Feel free to try the labs, ideally first locally using `KinD` or `k3d` for example, before testing on a cloud deployment like `GKE` or `EKS`.

Blog to likely follow, so stay tuned :)

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

### Using Kustomize
You can manually deploy any kustomize directory by just using `kubectl apply -k </path/to/dir>`

An example for deploying the `bookinfo-v1` overlay
```
kubectl apply -k bookinfo/overlay/bookinfo-v1/default/
```

To view the full configuration of an overlay you can run the command `kubectl kustomize </path/to/dir>`

An example using the same `bookinfo-v1` overlay as above
```
kubectl kustomize bookinfo/overlay/bookinfo-v1/default/
```

## ArgoCD
In addition to the library of applications organized using kustomize, this repo aims to provide a corresponding argocd `Application` CRD for each kustomize overlay. Combining the two tools allows us to continue on our GitOps journey by introducing the concept of keeping our deployments in sync with Git through a control loop mechanism.

The labs below provide steps to deploying examples found in our workshops while using this gitops-library as our source of truth for configuration.

## Table of Contents - Labs
- [installing argocd](https://github.com/solo-io/gitops-library/tree/main/argocd)
- [installing gloo-edge](https://github.com/solo-io/gitops-library/tree/main/gloo-edge)
  - [configuring gloo-fed](https://github.com/solo-io/gitops-library/tree/main/gloo-edge#configuring-gloo-fed)
  - [deploy and configure keycloak](https://github.com/solo-io/gitops-library/tree/main/keycloak)
  - [deploy hipstershop and expose with gloo-edge](https://github.com/solo-io/gitops-library/tree/main/hipstershop/hipstershop-edge.md)
  - [walkthrough bookinfo gloo-edge features demo](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-edge.md)
- [installing gloo-mesh](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh)
  - [register cluster to gloo-mesh using meshctl](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh#register-cluster-using-meshctl)
  - [deploying gloo-mesh addons](https://github.com/solo-io/gitops-library/blob/main/gloo-mesh/gloo-mesh-addons.md)
  - [creating a virtual mesh](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh/virtualmesh.md)
- [installing istio](https://github.com/solo-io/gitops-library/tree/main/istio)
  - [installing istio-addons](https://github.com/solo-io/gitops-library/tree/main/istio#install-istio-addons)
  - [deploy single cluster hipstershop istio demo app](https://github.com/solo-io/gitops-library/tree/main/hipstershop/hipstershop-mesh.md)
  - [deploy single cluster bookinfo istio demo app](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-mesh-singlecluster.md)
  - [deploy multi cluster bookinfo istio demo app](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-mesh-multicluster.md)
  - [bookinfo multi cluster gloo-mesh-gateway lab](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-multicluster-gmg.md)
- [installing gloo-portal](https://github.com/solo-io/gitops-library/tree/main/gloo-portal)
  - [deploying gloo-portal petstore demo](https://github.com/solo-io/gitops-library/tree/main/petstore)
- [Installing argo workflows](./argo-workflows/README.md)

## e2e gloo-mesh multicluster demo
If you would like to run through the Gloo Mesh multicluster demo end-to-end, you can do so by running the script
```
./multi-mesh-demo.sh $LICENSE_KEY
```

Resource Requirements:
- This demo has been tested on 1x `n2-standard-4` instance for `mgmt` cluster
- This demo has been tested on 2x `n2-standard-4` instances for `cluster1` and `cluster2`

Note:
- If a license key is not provided, the script will prompt for a valid Gloo Mesh license key
- By default, the script expects to deploy into three clusters named `mgmt`, `cluster1`, and `cluster2`. This is configurable by changing the variables in the `gm-multicluster-script.sh`. A check is done to ensure that the defined contexts exist before proceeding with the installation.

## e2e gloo-edge single cluster demo
If you would like to run through the Gloo Edge single cluster demo end-to-end, you can do so by running the script
```
./edge-demo.sh $LICENSE_KEY
```

Resource Requirements:
- This demo has been tested on 2x `n2-standard-4` instances

Note:
- If a license key is not provided, the script will prompt for a valid Gloo Edge license key
- The script assumes the current context as the one to be used for deploy. Use `kubectl config use-context <context>` to switch to the proper cluster that you desire
- If there is no current-context defined, the script will exit.

## e2e gloo-portal + gloo-edge single cluster demo
If you would like to run through the Gloo Edge single cluster demo end-to-end, you can do so by running the script
```
./portal-edge-demo.sh $LICENSE_KEY
```

Resource Requirements:
- This demo has been tested on 2x `n2-standard-4` instances

Note:
- If a license key is not provided, the script will prompt for a valid Gloo Edge license key
- The script assumes the current context as the one to be used for deploy. Use `kubectl config use-context <context>` to switch to the proper cluster that you desire
- If there is no current-context defined, the script will exit.

## Contributing
Interested in contributing an example configuration to gitops-library? Take a look at the example walkthrough in the `CONTRIBUTING.md` for more details on structure and workflow