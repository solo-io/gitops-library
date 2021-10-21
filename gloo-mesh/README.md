# gloo-mesh

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

## Note on Single vs. Multicluster labs
The following instructions add a flag `--context <context>` to the kubectl commands in order to direct the deploy to a specific cluster. For Single cluster demonstrations, the Gloo Mesh control plane and data plane can live on a single cluster (i.e. `cluster1`) whereas in a Production multi cluster setup we would recommend that the Gloo Mesh control plane live in a seperate `mgmt` cluster while the dataplane(s) reside in their own individual clusters (i.e. `cluster1` and `cluster2`)

## installing gloo mesh
Navigate to the `gloo-mesh` directory
```
cd gloo-mesh
```

Using your favorite text editor, replace the helm value `license_key: <INSERT_LICENSE_KEY_HERE>` in the `argo/<version>/gloo-mesh-ee-helm.yaml` manifest
```
helm:
      values: |
        license_key: <INSERT_LICENSE_KEY_HERE>
```

### Deploy the `gloo-mesh-ee-helm.yaml` app

**NOTE:** 
- Single Cluster Demo - `--context cluster1`
- Multi Cluster Demo - `--context mgmt`
```
kubectl apply -f argo/1-1-2/gloo-mesh-ee-helm.yaml --context <cluster>
```

You can run the `wait-for-rollout.sh` script to watch deployment progress. Be sure to replace the `<context>` with the right cluster, if not provided it will assume the `current-context`
```
../tools/wait-for-rollout.sh deployment enterprise-networking gloo-mesh 10 mgmt
```

Output should look similar to below:
```
$ ../tools/wait-for-rollout.sh deployment enterprise-networking gloo-mesh 10
Waiting 10 seconds for deployment enterprise-networking to come up.
deployment "enterprise-networking" successfully rolled out
Waiting 20 seconds for deployment enterprise-networking to come up.
deployment "enterprise-networking" successfully rolled out
```

### register cluster using meshctl
Run the script `scripts/meshctl-register.sh` to install the `meshctl` CLI and easily register your remote clusters to gloo-mesh control plane. 
```
./scripts/meshctl-register.sh <mgmt_context> <remote_context>
```

A couple examples below:
```
# gloo-mesh control plane in a seperate mgmt cluster
./scripts/meshctl-register.sh mgmt cluster1
./scripts/meshctl-register.sh mgmt cluster2

# gloo-mesh control plane in same cluster as cluster1
./scripts/meshctl-register.sh cluster1 cluster1
./scripts/meshctl-register.sh cluster1 cluster2
```

### access gloo mesh dashboard
access gloo mesh dashboard at `http://localhost:8090`:
```
kubectl port-forward -n gloo-mesh svc/dashboard 8090
```

## Next Steps for Single and Multi Cluster Labs - Deploy Istio
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)