# How to Contribute to gitops-library
This guide will walk through an example on how to contribute your own examples to gitops-library

Preference is to have the root-level directory specify the type of technology/application to be deployed (i.e. cert-manager, istio, gloo-mesh, etc.)

Nested in each should be three directories:
- `argo` - directory for argo applications which reference overlays in their path
- `overlay` - references bases and provides environment/user/cluster specific configuration through patches
- `base` - provide the base manifests

## Kustomize Structure Overview
This repo is structured using kustomize bases and overlays to foster re-use of configuration where possible. 

### base
base manifests are organized here. All overlay layers should inherit their configuration from the base manifests. Leave out instance-specific or environment-specific config out of the base manifests such as namespaces as these will be added/patched in the overlays. This helps us to preserve base configurations for reuse and to avoid configuration drift.

### overlay
Overlays do exactly as the name, and layer over base manifests and can additionally provide configuration that can be specific to the cluster using kustomize. A few examples of kustomize options would be adding `secrets` and `configMaps` using the `configMapGenerator` and `secretGenerators` built into kustomize. Another being leveraging the `patchesStrategicMerge` or `patchesJson6902` features which can be pretty powerful.

 An few examples of how overlays can be useful:
- reuse base manifest(s) but create overlays for prod, staging, dev, test
- reuse an existing overlay but create different `configmaps`, `secrets`, `labels`
- reuse an existing overlay but patch/add more configuration (i.e. Cloud to On-Prem/OpenShift environments)
- create overlays to organize multi-cloud or multi-cluster configuration

## Example walkthrough
The `bombardier-loadgen` directory is a simple example containing just a single deployment that can help illustrate how to configure a new overlay

Navigate to the `bombardier-loadgen` directory you will see the standard structure containing `argo`, `base`, and `overlay` directories
![](https://github.com/solo-io/gitops-library/blob/main/images/contributing1.png)

In the `base` directory lives our base `bombardier.yaml` deployment and a `kustomization.yaml` that references it
```
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# list of Resource Config to be Applied
resources:
- bombardier.yaml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: bombardier
  name: bombardier
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bombardier
  template:
    metadata:
      labels:
        app: bombardier
    spec:
      containers:
      - name: bombardier
        image: alpine/bombardier
        imagePullPolicy: IfNotPresent
        command: ["/bin/sh"]
        args: ["-c", "for run in $(seq 1 10); do bombardier -c 5 -d 20s -r 10 -p i,p,r ${URL}; done"]
```

As you can see, there is a variable `${URL}` that is expected to be patched in order for this to work. As this variable is specific to the domain of the application we want to point this load generator to, which can be a different URL per app, we will create an overlay in the next step to specify this.

### Navigate to overlay directory
If you navigate to the `bombardier-loadgen/overlay` directory you should see a few examples already available to be consumed
![](https://github.com/solo-io/gitops-library/blob/main/images/contributing2.png)

Lets take a look at the `bombardier-loadgen/overlay/bookinfo-loadgen-istio-ingressgateway` overlay. This overlay is pretty simple:

Taking a look at the `kustomization.yaml`:
```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
- ../../base/default/

namespace: istio-system

patchesStrategicMerge:
- patch/cmd-patch.yaml
```

Taking a look at the `patch/cmd-patch.yaml`:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bombardier
spec:
  template:
    spec:
      containers:
      - name: bombardier
        command: ["/bin/sh"]
        args: ["-c", "for run in $(seq 1 100); do bombardier -c 1 -d 60s -r 10 -p i,p,r http://istio-ingressgateway.istio-system/productpage; done"]
```

Here in this `kustomization.yaml` example we are reusing the `base` manifest described in the section above which is referenced by the relative path
```
bases:
- ../../base/default/
```

We then have to patch over the `${URL}` parameter, in our case `http://istio-ingressgateway.istio-system/productpage`, and provide the reference in our kustomization. In our case we will be using `patchesStrategicMerge` feature in kustomize. This use-case is simple, but essentially anything under `spec:` in the manifest can be configured with a patch (or multiple layered patches provided as a list). Simplifying a single mono-patch into multiple-patches can help to simplify readability as well as potentially reusability in certain cases.
```
patchesStrategicMerge:
- patch/cmd-patch.yaml
```

Additionally in this example you can see that we can use kustomize to specify `namespace: istio-system` for every object in the `kustomization.yaml`. This can be useful so that it is not necessary to manage the `namespace:` parameter in each manifest separately, which then allows for simpler re-use of the bases/overlays

## View your completed configuration:
To view your completed configuration to ensure correctness you can use the command `kubectl kustomize <path/to/dir>`
```
% kubectl kustomize bombardier-loadgen/overlay/bookinfo-loadgen-istio-ingressgateway
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: bombardier
  name: bombardier
  namespace: istio-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bombardier
  template:
    metadata:
      labels:
        app: bombardier
    spec:
      containers:
      - args:
        - -c
        - for run in $(seq 1 100); do bombardier -c 1 -d 60s -r 10 -p i,p,r http://istio-ingressgateway.istio-system/productpage;
          done
        command:
        - /bin/sh
        image: alpine/bombardier
        imagePullPolicy: IfNotPresent
        name: bombardier
```

## Manually deploy your app if desired
You can also do a dry run by passing `--dry-run=client` along with `kubectl apply -k`
```
% kubectl apply -k bombardier-loadgen/overlay/bookinfo-loadgen-istio-ingressgateway --dry-run=client
deployment.apps/bombardier created (dry run)
```

If either of these steps fails, you will have to explore the error message to see what has been configured incorrectly.

## Create an Argo Application to sync your application to git
Now that our overlay is configured correctly, build an argo application that references the path to this overlay in the `argo` directory

An example already exists here named `bookinfo-loadgen-istio-ingressgateway.yaml`
```
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bookinfo-loadgen-istio-ingressgateway
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/solo-io/gitops-library
    targetRevision: HEAD
    path: bombardier-loadgen/overlay/bookinfo-loadgen-istio-ingressgateway/
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: false # Specifies if resources should be pruned during auto-syncing ( false by default ).
      selfHeal: false # Specifies if partial app sync should be executed when resources are changed only in target Kubernetes cluster and no git change detected ( false by default ).
```

Taking a look at the above, we are doing the following:
- deploying an argo `Application` named `bookinfo-loadgen-istio-ingressgateway`
- referencing a github `repoURL: https://github.com/solo-io/gitops-library`
- defining the path to our overlay `path: bombardier-loadgen/overlay/bookinfo-loadgen-istio-ingressgateway/`

And thats it! Now if you have argocd installed on your cluster you can deploy your app which will be synced to git using `kubectl apply -f bookinfo-loadgen-istio-ingressgateway.yaml`