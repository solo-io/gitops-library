# bookinfo gloo mesh gateway demo (multi cluster)

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
For this lab we will be demonstrating Gloo Mesh Gateway (GMG) as a replacement for the default Istio Ingress Gateway. Gloo Mesh Gateway is an abstraction built on top of Istio's ingress gateway model. Leveraging GMG, a user can go beyond the standard features in upstream and provide capabilities such as `extauth`, `ratelimiting` which exist today in the Gloo Edge Enterprise product. GMG also aims to simplify the configuration of ingress traffic rules, especially when it comes to multi-cluster and multi-mesh scenarios.

For the lab below we will be configuring a [multi-cluster, multi gateway](https://docs.solo.io/gloo-mesh-enterprise/latest/img/gateway/gateway-multi-cluster-multi-gateway.png) setup using the bookinfo application.


## If following from previous labs, uninstall existing default istio ingressgateway and policies
Navigate to the `bookinfo` directory
```
cd bookinfo
```

```
kubectl delete -f argo/deploy/workshop/istio-ig/bookinfo-mgmt-trafficshift.yaml --context mgmt
kubectl delete -f argo/deploy/workshop/istio-ig/bookinfo-cluster1-istio-ig-vs.yaml --context cluster1
kubectl delete -f argo/deploy/workshop/istio-ig/bookinfo-cluster2-istio-ig-vs.yaml --context cluster2
```

**NOTE:** You can also skip the section below if you already have bookinfo deployed on `cluster1` and `cluster2` from the previous lab.

## deploy bookinfo application on cluster1
Navigate to the `bookinfo` directory
```
cd bookinfo
```

Deploy the bookinfo (no reviews) app on `cluster1`
```
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster1-noreviews.yaml --context cluster1
```

### view kustomize configuration
If you are curious to review the overlay configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/gloo-mesh-workshop/bookinfo-cluster1-noreviews/
```

You can see that the `reviews-v1` and `reviews-v2` deployment replicas have been scaled down to 0
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

Check to see that `reviews-v1` and `reviews-v2` have been scaled down by running `kubectl get pods --context cluster1`
```
% k get pods --context cluster1
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-79c697d759-zmx7j       2/2     Running   0          26m
ratings-v1-7d99676f7f-7stl7       2/2     Running   0          26m
productpage-v1-65576bb7bf-mcjfr   2/2     Running   0          26m
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

What we should expect in this overlay implementation is that `reviews-v1` (no stars), `reviews-v2` (black stars), and `reviews-v3` (red stars) should all be present. You can check this by running the command `kubectl get pods -n default --context cluster2`
```
% kubectl get pods -n default --context cluster2
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-79c697d759-vc4pm       2/2     Running   0          155m
ratings-v1-7d99676f7f-9rsw4       2/2     Running   0          155m
reviews-v2-6c5bf657cf-s54dh       2/2     Running   0          155m
reviews-v3-5f7b9f4f77-fphzc       2/2     Running   0          155m
reviews-v1-987d495c-99rbk         2/2     Running   0          155m
productpage-v1-65576bb7bf-tthjf   2/2     Running   0          155m
```

# Lab

### 1a - deploy default gloo mesh gateway with virtualgateway, virtualhost, and routetable onto mgmt cluster (no reviews should be available)
Note that the config below is deployed only to the `mgmt` context where our Gloo Mesh control plane resides, rather than having to manage deployments to each cluster individually. Gloo Mesh will take care of the translation into Istio CRs in each individual cluster, reducing complexity and configuration of the system.
```
kubectl apply -f argo/deploy/workshop/gmg/bookinfo-gmg-simple-1a.yaml --context mgmt
```

### view kustomize configuration
If you are curious to review the `1a-simple-cluster1` GMG configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/gloo-mesh-workshop/gmg/1a-simple-cluster1
```

Because our `RouteAction` points both ingress gateways to `cluster1` as our kube service destination and there are no reviews services available on `cluster1` we should expect to see an error when fetching product reviews when navigating to the ingressgateway of either cluster
```
routeAction:
      destinations:
      - kubeService:
          clusterName: cluster1
          name: productpage
          namespace: default
```

### 1b - point ingress traffic for both clusters to reviews on cluster2
```
kubectl apply -f argo/deploy/workshop/gmg/bookinfo-gmg-simple-1b.yaml --context mgmt
```

### view kustomize configuration
If you are curious to review the `1b-simple-cluster2` GMG configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/gloo-mesh-workshop/gmg/1b-simple-cluster2
```

Because our `RouteAction` points to `cluster2` as our kube service destination and `reviews-v1`, `reviews-v2`, and `reviews-v3` services are available on `cluster2` we should expect to see all three reviews available on either ingress gateway.
```
routeAction:
      destinations:
      - kubeService:
          clusterName: cluster2
          name: productpage
          namespace: default
```

### 2 - Multi Weighted Destination
```
kubectl apply -f argo/deploy/workshop/gmg/bookinfo-gmg-2a-multi.yaml --context mgmt
```

### view kustomize configuration
If you are curious to review the `2a-multi` GMG configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/gloo-mesh-workshop/gmg/2a-multi
```

You can see the weights of the `trafficShift` policies below, since there are no reviews services available on `cluster1` we have decided to direct traffic to `cluster2` resources with `reviews-v1` (40%), `reviews-v2` (30%), and `reviews-v3` (30%).
```
policy:
    trafficShift:
      destinations:
      - kubeService:
          clusterName: cluster1
          name: reviews
          namespace: default
          subset:
            version: v1
        weight: 0
      - kubeService:
          clusterName: cluster1
          name: reviews
          namespace: default
          subset:
            version: v2
        weight: 0
      - kubeService:
          clusterName: cluster1
          name: reviews
          namespace: default
          subset:
            version: v3
        weight: 0
      - kubeService:
          clusterName: cluster2
          name: reviews
          namespace: default
          subset:
            version: v1
        weight: 40
      - kubeService:
          clusterName: cluster2
          name: reviews
          namespace: default
          subset:
            version: v2
        weight: 30
      - kubeService:
          clusterName: cluster2
          name: reviews
          namespace: default
          subset:
            version: v3
        weight: 30
```

## validate
You can use the following commands to validate that the requests are handled by `cluster2` regardless of which ingressgateway is serving traffic
```
kubectl --context cluster2 logs -l app=reviews -c istio-proxy -f
```

You should see a line like below each time you refresh the web page
```
[2020-10-12T14:19:35.996Z] "GET /reviews/0 HTTP/1.1" 200 - "-" "-" 0 295 6 6 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.75 Safari/537.36" "d18da89b-8682-4e8d-9284-b3d5ff78f2f7" "reviews:9080" "127.0.0.1:9080" inbound|9080|http|reviews.default.svc.cluster.local 127.0.0.1:41542 192.168.163.201:9080 192.168.163.221:42110 outbound_.9080_.version-v1_.reviews.default.svc.cluster.local default
```

# Recover cluster1 services and slowly shift traffic back
Let's bring back our `reviews-v1` and `reviews-v2` services on `cluster1`
```
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster1.yaml --context cluster1
```

We should see our reviews services available now if we run `kubectl get pods --context cluster1`
```
% kubectl get pods --context cluster1
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-79c697d759-zmx7j       2/2     Running   0          49m
ratings-v1-7d99676f7f-7stl7       2/2     Running   0          49m
productpage-v1-65576bb7bf-mcjfr   2/2     Running   0          49m
reviews-v1-987d495c-mcg4z         2/2     Running   0          27s
reviews-v2-6c5bf657cf-7nmf4       2/2     Running   0          27s
```

Now we can incrementally shift traffic back to `cluster1` by using the weighted destinations and subsets. For example, the overlay `2b-multi` demonstrates this
```
kubectl kustomize overlay/gloo-mesh-workshop/gmg/2b-multi
```

See the weighted destinations below where we let `reviews-v1` service in `cluster1` to take 25% of the traffic
```
policy:
    trafficShift:
      destinations:
      - kubeService:
          clusterName: cluster1
          name: reviews
          namespace: default
          subset:
            version: v1
        weight: 25
      - kubeService:
          clusterName: cluster1
          name: reviews
          namespace: default
          subset:
            version: v2
        weight: 0
      - kubeService:
          clusterName: cluster1
          name: reviews
          namespace: default
          subset:
            version: v3
        weight: 0
      - kubeService:
          clusterName: cluster2
          name: reviews
          namespace: default
          subset:
            version: v1
        weight: 15
      - kubeService:
          clusterName: cluster2
          name: reviews
          namespace: default
          subset:
            version: v2
        weight: 30
      - kubeService:
          clusterName: cluster2
          name: reviews
          namespace: default
          subset:
            version: v3
        weight: 30
```

### trafficshift back to cluster1
Deploy this trafficshift overlay to shift the weights incrementally back to cluster1 as described above
```
kubectl apply -f argo/deploy/workshop/gmg/bookinfo-gmg-2b-multi.yaml --context mgmt
```

## validate
You can use the following commands to validate that the requests are now handled by both `cluster1` and `cluster2`
```
kubectl --context cluster1 logs -l app=reviews -c istio-proxy -f
kubectl --context cluster2 logs -l app=reviews -c istio-proxy -f
```

## cleanup
To cleanup, remove the Gloo Mesh Gateway configs
```
kubectl delete -f argo/deploy/workshop/gmg/bookinfo-gmg-2b-multi.yaml --context mgmt
``` 

To remove bookinfo application
```
kubectl delete -f argo/deploy/workshop/bookinfo-workshop-cluster1-noreviews.yaml --context cluster1
kubectl delete -f argo/deploy/workshop/bookinfo-workshop-cluster2.yaml --context cluster2
```

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)