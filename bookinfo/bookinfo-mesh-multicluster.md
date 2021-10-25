# bookinfo istio demo (multi cluster)

**Quick note on Prerequisites:** Please ensure that the prerequisites below are met before moving forward in order to ensure a smooth flow. If you have been following the single cluster labs, at this point you may need to stand up a few more clusters and run through the necessary installations for those clusters before proceeding. You should have three cluster contexts named: `mgmt`, `cluster1`, and `cluster2`

## Prerequisites
- Kubernetes clusters `mgmt`, `cluster1`, and `cluster2` up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd) deployed on all three clusters
- gloo-mesh - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh) deployed on the `mgmt` cluster
- `cluster1` and `cluster2` registered to the gloo-mesh control plane - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh#register-cluster-using-meshctl)
- gloo mesh addons deployed [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/blob/main/gloo-mesh/gloo-mesh-addons.md)
- istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio) deployed on `cluster1` and `cluster2`
- virtualmesh deployed - [Follow this Tutorial Here]([Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh/virtualmesh.md) on `mgmt` cluster

## Demo Architecture
![](https://files.gitbook.com/v0/b/gitbook-28427.appspot.com/o/assets%2F-MV36LeHUPE5MXsiAGhM%2Fsync%2Fb04e224f869969a1b058b07833fa96494cd8a935.png?generation=1614995920661313&alt=media)

For this lab we will be demonstrating traffic shift and failover across multiple clusters using Gloo Mesh. The diagram above depicts the architecture. In this example, `bookinfo` application is deployed on both `cluster1` and `cluster2` which are both in our `VirtualMesh`. In `cluster1` however, the `reviews-v1` and `reviews-v2` applications have been scaled down to 0. From here we will show how to use the `VirtualDestination` CR and the `TrafficPolicy` CR in Gloo Mesh to showcase some powerful capabilities of multi-cluster service mesh.

## deploy bookinfo application on cluster1
Navigate to the `bookinfo` directory
```
cd bookinfo
```

Deploy the bookinfo w/ no reviews app on `cluster1`
```
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster1-noreviews.yaml --context cluster1
```

### view kustomize configuration
If you are curious to review the entire hipstershop-istio configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/gloo-mesh-workshop/bookinfo-cluster1-noreviews
```

A key difference between the `bookinfo-v1-default` overlay and the `bookinfo-v1-istio` overlay is the use of the label `istio-injection=enabled` on the bookinfo-v1 namespace. Other than that, this example shows a very good use-case for Kustomize as we use bases/overlays to minimize duplication of configuration between the default and istio overlays.
```
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio-injection: enabled
  name: bookinfo-v1
```

You can also see that the `reviews-v1` and `reviews-v2` deployment replicas have been scaled down to 0
```
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: reviews
    version: v1
  name: reviews-v1
spec:
  replicas: 0
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: reviews
    version: v2
  name: reviews-v2
spec:
  replicas: 0
```

watch status of bookinfo deployment for `cluster1` using `kubectl get pods --context cluster1`:
```
% kubectl get pods --context cluster1
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-79c697d759-pcbxt       2/2     Running   0          142m
productpage-v1-65576bb7bf-bkg4x   2/2     Running   0          142m
ratings-v1-7d99676f7f-2glpf       2/2     Running   0          142m
```

## deploy bookinfo application on cluster2
Deploy the bookinfo app with all reviews on `cluster2`
```
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster2.yaml --context cluster2
```

### view kustomize configuration
If you are curious to review the entire bookinfo configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/gloo-mesh-workshop/bookinfo-cluster2
```

watch status of bookinfo deployment for `cluster2` using `kubectl get pods --context cluster2`:
```
% kubectl get pods --context cluster2
NAME                              READY   STATUS    RESTARTS   AGE
reviews-v1-987d495c-kvd5h         2/2     Running   0          142m
reviews-v3-5f7b9f4f77-kb5sj       2/2     Running   0          142m
ratings-v1-7d99676f7f-ltlpx       2/2     Running   0          142m
productpage-v1-65576bb7bf-5h27h   2/2     Running   0          142m
reviews-v2-6c5bf657cf-cf9hj       2/2     Running   0          142m
details-v1-79c697d759-bvdtw       2/2     Running   0          142m
```

You can also see that the `reviews-v1`, `reviews-v2`, and `reviews-v3` deployments exist on `cluster2` but not on `cluster1`

## deploy ingress gateways and virtualservices for cluster1 and cluster2
Expose our bookinfo service on `cluster1` and `cluster2` by deploying an istio ingressgateway and virtualservice on each cluster
```
kubectl apply -f argo/deploy/workshop/istio-ig/bookinfo-cluster1-istio-ig.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/workshop/istio-ig/bookinfo-cluster2-istio-ig.yaml --context ${cluster2_context}
```

### view kustomize configuration
If you are curious to review the ingressgateway and virtualservice configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/gloo-mesh-workshop/istio-ig/cluster1/
kubectl kustomize overlay/gloo-mesh-workshop/istio-ig/cluster2/
```

## navigate to bookinfo application on cluster1
get the istio-ingressgateway URL
```
kubectl get svc -n istio-system --context cluster1
```

output should look similar to below:
```
% kubectl get svc -n istio-system --context cluster1
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                                                                      AGE
istio-ingressgateway   LoadBalancer   10.99.240.177   35.245.29.226   80:30929/TCP,443:31674/TCP,15021:32291/TCP,15443:31746/TCP,15012:32582/TCP,15017:30303/TCP   50m
istiod                 ClusterIP      10.99.240.186   <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP                                                        50m
```

Navigate to the `istio-ingressgateway` EXTERNAL-IP
```
open http://35.245.29.226/productpage
```
You should see that on `cluster1` that there are no product reviews available. Take note of the IP address `35.245.29.226` for the ingress gateway for `cluster1` as we move along the lab

![](https://github.com/solo-io/gitops-library/blob/main/images/bi1.png)

## navigate to bookinfo application on cluster2
get the istio-ingressgateway URL
```
kubectl get svc -n istio-system --context cluster2
```

output should look similar to below:
```
% kubectl get svc -n istio-system --context cluster2
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                                                                                      AGE
istio-ingressgateway   LoadBalancer   10.135.253.118   34.150.155.157   80:31845/TCP,443:32474/TCP,15021:32678/TCP,15443:30089/TCP,15012:31593/TCP,15017:30324/TCP   52m
istiod                 ClusterIP      10.135.254.109   <none>           15010/TCP,15012/TCP,443/TCP,15014/TCP                                                        52m
```

Navigate to the `istio-ingressgateway` EXTERNAL-IP
```
open http://34.150.155.157/productpage
```
You should see that on `cluster2` that all the reviews are available (black stars, red stars, and no stars) if you refresh a few times.

![](https://github.com/solo-io/gitops-library/blob/main/images/bi2.png)


## Demonstrate Traffic Shift and Failover
In order to demonstrate traffic shift and failover capabilities, we will leverage the `VirtualDestination` CR and the `TrafficPolicy` CR in Gloo Mesh.

Use the kustomize command below to view the `VirtualDestination` and `TrafficShift` configs:
```
kubectl kustomize overlay/gloo-mesh-workshop/trafficshift/
```

Output should look similar to below:
```
apiVersion: networking.enterprise.mesh.gloo.solo.io/v1beta1
kind: VirtualDestination
metadata:
  name: reviews-global
  namespace: gloo-mesh
spec:
  hostname: reviews.global
  localized:
    destinationSelectors:
    - kubeServiceMatcher:
        labels:
          app: reviews
    outlierDetection:
      baseEjectionTime: 120s
      consecutiveErrors: 1
      interval: 5s
      maxEjectionPercent: 100
  port:
    number: 9080
    protocol: http
  virtualMesh:
    name: virtual-mesh
    namespace: gloo-mesh
---
apiVersion: networking.mesh.gloo.solo.io/v1
kind: TrafficPolicy
metadata:
  name: reviews-shift-failover
  namespace: gloo-mesh
spec:
  destinationSelector:
  - kubeServiceRefs:
      services:
      - clusterName: cluster1
        name: reviews
        namespace: default
  policy:
    trafficShift:
      destinations:
      - virtualDestination:
          name: reviews-global
          namespace: gloo-mesh
          subset:
            version: v1
        weight: 50
      - virtualDestination:
          name: reviews-global
          namespace: gloo-mesh
          subset:
            version: v2
        weight: 50
  sourceSelector:
  - kubeWorkloadMatcher:
      namespaces:
      - default
```

Here we have created a `VirtualDestination` to define a new hostname (`reviews.global`) that will be backed by the reviews microservice runnings on both clusters.

We can then define another `TrafficPolicy` to make sure all the requests for the reviews microservice on the local cluster will be handled by the VirtualDestination we've just created.

### deploy virtualdestination and trafficpolicy to demonstrate trafficshift & failover
```
kubectl apply -f argo/deploy/workshop/istio-ig/bookinfo-cluster1-cluster2-trafficshift.yaml --context mgmt
```

## navigate to bookinfo application on cluster1
If you navigate back to the bookinfo application on `cluster1` reviews should now be visible while there's no reviews service deployed on the first cluster. Take note of the IP address `35.245.29.226` for the ingress gateway for `cluster1` in the screenshots below

![](https://github.com/solo-io/gitops-library/blob/main/images/bi3.png)

![](https://github.com/solo-io/gitops-library/blob/main/images/bi4.png)

Take note that we can control the weighting as well as version subsets that we want to shift traffic to. As defined from the config you should see `reviews-v1` (no stars) and `reviews-v2` (black stars) at a 50/50 weight.
```
policy:
    trafficShift:
      destinations:
      - virtualDestination:
          name: reviews-global
          namespace: gloo-mesh
          subset:
            version: v1
        weight: 50
      - virtualDestination:
          name: reviews-global
          namespace: gloo-mesh
          subset:
            version: v2
        weight: 50
```

## validate
You can use the following command to validate that the requests are handled by the second cluster
```
kubectl --context cluster2 logs -l app=reviews -c istio-proxy -f
```

You should see a line like below each time you refresh the web page
```
[2020-10-12T14:19:35.996Z] "GET /reviews/0 HTTP/1.1" 200 - "-" "-" 0 295 6 6 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36" "d18da89b-8682-4e8d-9284-b3d5ff78f2f7" "reviews:9080" "127.0.0.1:9080" inbound|9080|http|reviews.default.svc.cluster.local 127.0.0.1:41542 192.168.163.201:9080 192.168.163.221:42110 outbound_.9080_.version-v1_.reviews.default.svc.cluster.local default
```

## Gloo Mesh Dashboard
If you navigate back to the UI and feel free to click around to explore the details and configurations of your virtual mesh, bookinfo app, as well as individual mesh policies, gateways, explore the graph, and more!

To navigate to the Gloo Mesh dashboard you can run the port-forward command and access at http://localhost:8090
```
kubectl port-forward -n gloo-mesh svc/dashboard 8090
```

![](https://github.com/solo-io/gitops-library/blob/main/images/gm1.png)

![](https://github.com/solo-io/gitops-library/blob/main/images/gm2.png)

![](https://github.com/solo-io/gitops-library/blob/main/images/gm3.png)

## cleanup
To remove the ingress gateway and policies from `cluster1` and `cluster2`
```
kubectl delete -f argo/deploy/workshop/istio-ig/bookinfo-cluster1-cluster2-trafficshift.yaml --context mgmt
kubectl delete -f argo/deploy/workshop/istio-ig/bookinfo-cluster1-istio-ig.yaml --context cluster1
kubectl delete -f argo/deploy/workshop/istio-ig/bookinfo-cluster2-istio-ig.yaml --context cluster2
``` 

## Next Steps - Replace Istio ingressgateway with Gloo Mesh Gateway
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-multicluster-gmg.md)