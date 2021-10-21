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
If you are curious to review the entire hipstershop-istio configuration in more detail, run the kustomize command below
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

## navigate to bookinfo application on cluster1
get the istio-ingressgateway URL
```
kubectl get svc -n istio-system --context cluster1
```

output should look similar to below:
```
% kubectl get svc -n istio-system --context cluster1
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
istiod                 ClusterIP      10.43.77.155    <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP        9m17s
istio-ingressgateway   LoadBalancer   10.43.230.201   172.20.0.5    15021:32197/TCP,80:30411/TCP,443:31521/TCP   9m10s
kiali                  ClusterIP      10.43.96.183    <none>        20001/TCP,9090/TCP                           8m18s
zipkin                 ClusterIP      10.43.200.101   <none>        9411/TCP                                     8m18s
jaeger-collector       ClusterIP      10.43.115.228   <none>        14268/TCP,14250/TCP,9411/TCP                 8m18s
prometheus             ClusterIP      10.43.0.137     <none>        9090/TCP                                     8m18s
grafana                ClusterIP      10.43.140.40    <none>        3000/TCP                                     8m18s
tracing                ClusterIP      10.43.52.37     <none>        80/TCP,16685/TCP                             8m18s
```

Navigate to the `istio-ingressgateway` EXTERNAL-IP
```
open http://172.20.0.5/productpage
```
You should see that on `cluster1` that there are no reviews available 

## navigate to bookinfo application on cluster2
get the istio-ingressgateway URL
```
kubectl get svc -n istio-system --context cluster2
```

output should look similar to below:
```
% kubectl get svc -n istio-system --context cluster2
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                                      AGE
istiod                 ClusterIP      10.43.134.163   <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP        6m46s
istio-ingressgateway   LoadBalancer   10.43.119.45    172.20.0.8    15021:30593/TCP,80:31415/TCP,443:31281/TCP   6m36s
jaeger-collector       ClusterIP      10.43.128.65    <none>        14268/TCP,14250/TCP,9411/TCP                 6m19s
kiali                  ClusterIP      10.43.199.154   <none>        20001/TCP,9090/TCP                           6m19s
tracing                ClusterIP      10.43.182.6     <none>        80/TCP,16685/TCP                             6m19s
grafana                ClusterIP      10.43.136.83    <none>        3000/TCP                                     6m19s
zipkin                 ClusterIP      10.43.194.143   <none>        9411/TCP                                     6m19s
prometheus             ClusterIP      10.43.246.71    <none>        9090/TCP  
```

Navigate to the `istio-ingressgateway` EXTERNAL-IP
```
open http://172.20.0.8/productpage
```
You should see that on `cluster2` that all the reviews are available 

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
kubectl apply -f argo/deploy/workshop/bookinfo-cluster1-cluster2-trafficshift.yaml --context mgmt
```

## navigate to bookinfo application on cluster1
If you navigate back to the bookinfo application on `cluster1` you should see that `reviews-v1` (no stars) and `reviews-v2` (black stars) should now be visible while there's no reviews service deployed on the first cluster.

## validate
You can use the following command to validate that the requests are handled by the second cluster
```
kubectl --context cluster2 logs -l app=reviews -c istio-proxy -f
```

You should see a line like below each time you refresh the web page
```
[2020-10-12T14:19:35.996Z] "GET /reviews/0 HTTP/1.1" 200 - "-" "-" 0 295 6 6 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36" "d18da89b-8682-4e8d-9284-b3d5ff78f2f7" "reviews:9080" "127.0.0.1:9080" inbound|9080|http|reviews.default.svc.cluster.local 127.0.0.1:41542 192.168.163.201:9080 192.168.163.221:42110 outbound_.9080_.version-v1_.reviews.default.svc.cluster.local default
```

## cleanup
To delete bookinfo application from `cluster1` and `cluster2` along with our traffic shift policies
```
kubectl delete -f argo/deploy/workshop/bookinfo-cluster1-cluster2-trafficshift.yaml --context mgmt
kubectl delete -f argo/deploy/workshop/bookinfo-workshop-cluster1-noreviews.yaml --context cluster1
kubectl delete -f argo/deploy/workshop/bookinfo-workshop-cluster2.yaml --context cluster2
``` 

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)