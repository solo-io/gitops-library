# Gloo Mesh VirtualMesh Lab
It is a common deployment practice to deploy your workloads across multiple clusters. However, when you are running multiple independent meshes, it becomes more challenging for services to talk to one another. While each mesh can act as it's own CA and sign it's own workloads, to achieve cluster-to-cluster communication the meshes need to be grouped together and the trust must be shared between them. In gloo-mesh, the `VirtualMesh` Custom Resource is used to simplify the grouping and deployment of a federated service mesh

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- gloo-mesh - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh)
- istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)

## Deploying a VirtualMesh
Now that we have deployed and configured our `mgmt`, `cluster1`, and `cluster2` clusters with Gloo Mesh + Istio, the next step is to unify these separate service meshes into a single unified `VirtualMesh`. [more on VirtualMesh here](https://docs.solo.io/gloo-mesh-enterprise/latest/concepts/concepts/#virtual-meshes)

### view virtualmesh
To view the config of our `VirtualMesh` run the kustomize command below
```
kubectl kustomize overlay/virtualmesh/rbac-enabled/
```

Output should look similar to below
```
% kubectl kustomize overlay/virtualmesh/rbac-enabled/
apiVersion: networking.mesh.gloo.solo.io/v1
kind: VirtualMesh
metadata:
  name: virtual-mesh
  namespace: gloo-mesh
spec:
  federation:
    selectors:
    - {}
  globalAccessPolicy: ENABLED
  meshes:
  - name: istiod-istio-system-cluster1
    namespace: gloo-mesh
  - name: istiod-istio-system-cluster2
    namespace: gloo-mesh
  mtlsConfig:
    autoRestartPods: true
    shared:
      rootCertificateAuthority:
        generated: {}
```

### create virtualmesh
```
kubectl apply -f argo/gloo-mesh-virtualmesh-rbac-enabled.yaml --context mgmt
```
Deploying the `VirtualMesh` above will unify the root identity between multiple service mesh installations so any intermediates are signed by the same Root CA and end-to-end mTLS between clusters and services can be established correctly.

**NOTE:** for our labs the `VirtualMesh` CR object is deployed in the `mgmt` cluster where the gloo-mesh control plane resides

Take a look at the VirtualMesh that was created in order to see more detail
```
kubectl get virtualmesh -n gloo-mesh virtual-mesh -o yaml
```

You can also describe it:
```
kubectl describe virtualmesh -n gloo-mesh virtual-mesh
```

## Gloo Mesh Dashboard
In the Gloo Mesh Dashboard, you should see that our two service meshes have now been unified into a single VirtualMesh named `virtual-mesh`

(Insert picture here)

## Next Steps - Deploy istio
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)