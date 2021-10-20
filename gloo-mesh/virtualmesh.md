# Gloo Mesh VirtualMesh Lab
It is a common deployment practice to deploy your workloads across multiple clusters. However, when you are running multiple independent meshes, it becomes more challenging for services to talk to one another. While each mesh can act as it's own CA and sign it's own workloads, to achieve cluster-to-cluster communication the meshes need to be grouped together and the trust must be shared between them. In gloo-mesh, the `VirtualMesh` Custom Resource is used to simplify the grouping and deployment of a federated service mesh

**Quick note on Prerequisites:** Please ensure that the prerequisites below are met before moving forward in order to ensure a smooth flow. If you have been following the single cluster labs, at this point you may need to stand up a few more clusters and run through the necessary installations for those clusters before proceeding. You should have three cluster contexts named: `mgmt`, `cluster1`, and `cluster2`

## Prerequisites
- Kubernetes clusters `mgmt`, `cluster1`, and `cluster2` up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd) deployed on all three clusters
- gloo-mesh - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh) deployed on the `mgmt` cluster
- `cluster1` and `cluster2` registered to the gloo-mesh control plane - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh#register-cluster-using-meshctl)
- istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio) deployed on `cluster1` and `cluster2`

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

## Next Steps - Deploy bookinfo application and run through workshop labs (multi cluster)
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-mesh-multicluster.md)