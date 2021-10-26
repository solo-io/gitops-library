# gloo-edge

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)

## kubectl contexts
Since we will potentially be using multiple clusters/contexts, it is useful to rename your contexts for a better experience
```
kubectl config get-contexts
kubectl config rename-contexts <current_name> <new_name>
export CONTEXT=<new_name>
```

## installing gloo-edge
Navigate to the `gloo-edge` directory
```
cd gloo-edge
```

### create license secret (enterprise edition)
If using Gloo Edge Enterprise, we will need to deploy a secret into the `gloo-system` namespace that contains the Enterprise license key

### set $LICENSE_KEY variable
```
export LICENSE_KEY=
```

### create gloo-system namespace
```
kubectl create ns gloo-system
```

### deploy secret

For Linux Users:
```
kubectl apply -f - <<EOF
apiVersion: v1
data:
  license-key: $(echo -n "${LICENSE_KEY}" | base64 -w 0)
kind: Secret
metadata:
  labels:
    app: gloo
    gloo: license
  name: license
  namespace: gloo-system
type: Opaque
EOF
```

For MacOS Users:
```
kubectl apply -f - <<EOF
apiVersion: v1
data:
  license-key: $(echo -n "${LICENSE_KEY}" | base64)
kind: Secret
metadata:
  labels:
    app: gloo
    gloo: license
  name: license
  namespace: gloo-system
type: Opaque
EOF
```

## deploy gloo edge
Once the Enterprise license key has been created, navigate to the version of Gloo Edge that you want and deploy the associated argo application.

For example, to deploy Gloo Edge Enterprise v1.8.9 with Gloo Fed enabled (default)
```
kubectl apply -f argo/ee/1-8-9/gloo-edge-ee-helm-1-8-9.yaml
```

## wait for rollout
You can run the `wait-for-rollout.sh` script to watch deployment progress
```
../tools/wait-for-rollout.sh deployment gateway gloo-system 10
```

Output should look similar to below:
```
$ ../tools/wait-for-rollout.sh deployment gateway gloo-system 10
No context specified. Using default context of cluster1
Waiting 10 seconds for deployment gateway to come up.
Error from server (NotFound): deployments.apps "gateway" not found
Waiting 20 seconds for deployment gateway to come up.
Waiting for deployment "gateway" rollout to finish: 0 of 1 updated replicas are available...
deployment "gateway" successfully rolled out
Waiting 30 seconds for deployment gateway to come up.
deployment "gateway" successfully rolled out
```

## configuring gloo-fed
gloo-fed is deployed by default as a sub-chart of the `gloo-edge` helm installation. By default, the gloo-edge install configures gloo-fed as part of the installation. Use this command below to check the status of `gloo-fed` in your cluster
```
../tools/wait-for-rollout.sh deployment gloo-fed gloo-system 10
```

Output should look similar to below
```
$ ../tools/wait-for-rollout.sh deployment gloo-fed gloo-system 10
No context specified. Using default context of cluster1
Waiting 10 seconds for deployment gloo-fed to come up.
Waiting 20 seconds for deployment gloo-fed to come up.
Waiting 30 seconds for deployment gloo-fed to come up.
<...>
deployment "gloo-fed" successfully rolled out
```

### registering your cluster to gloo-fed
To register your cluster to `gloo-fed`
```
glooctl cluster register --cluster-name ${CONTEXT} --remote-context ${CONTEXT} --remote-namespace gloo-system
```

### (optional) register a second cluster to gloo-fed
If you have a second cluster you would like to register to the gloo-fed console, follow the steps below

#### IMPORTANT: set correct variables for contexts
For example
```
export MGMT_CONTEXT=cluster1
export REMOTE_CONTEXT=cluster2
```

Then register the remote cluster
```
kubectl config use-context ${MGMT_CONTEXT}
glooctl cluster register --cluster-name ${REMOTE_CONTEXT} --remote-context ${REMOTE_CONTEXT} --remote-namespace gloo-system
```

**Note:** The glooctl command below needs to be run where the gloo fed management plane exists

### port-forward for gloo-fed console
```
kubectl port-forward svc/gloo-fed-console -n gloo-system 8090:8090
```

## Deploy gloo-edge with gloo-fed disabled
gloo-fed is a feature `gloo-edge` that is enabled default, the gloo-edge helm chart configures gloo-fed as part of the installation. Disabling gloo-fed is as simple as setting `gloo-fed.enabled=false` in the Gloo Edge Enterprise Helm chart. 

Since we are using gitops, we have already created an argo application [here](https://github.com/solo-io/gitops-library/blob/main/gloo-edge/argo/ee/1-8-9/gloo-edge-ee-helm-nofed-1-8-9.yaml) that disables gloo-fed so we can just deploy it.
```
kubectl apply -f argo/ee/1-8-9/gloo-edge-ee-helm-nofed-1-8-9.yaml
```

**NOTE:** Prior to Gloo Edge Enterprise v1.8.9, the Enterprise UI was only available if Gloo Federation was enabled. Starting in v1.8.9, the UI is included by default for all Gloo Edge Enterprise users as well. Note that if you have Gloo Federation enabled, the UI does not show any data until you register one or more clusters. If Gloo Federation is disabled, the UI shows the installed Gloo Edge instance automatically without cluster registration. See [this upgrade notice](https://docs.solo.io/gloo-edge/master/operations/upgrading/1.8.0/#enterprise-ui) for more details

## Uninstalling Gloo Edge
removing gloo-edge depends on which overlay path was installed when going through the installation lab. Please uninstall the argo application you originally installed
```
kubectl delete -f ../gloo-edge/argo/ee/<path/to/version/used>
```

## Next Steps - deploy keycloak
If you plan to follow along with the guides, it is recommended to install the keycloak argo application as well as we will be using this later.
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/keycloak)

