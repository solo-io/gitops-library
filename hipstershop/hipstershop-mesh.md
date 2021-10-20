# hipstershop istio demo

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- Istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)


## deploy hipstershop application
Navigate to the `hipstershop` directory
```
cd hipstershop
```

Deploy the hipstershop-istio app
```
kubectl apply -f argo/deploy/hipstershop-istio.yaml
```

### view kustomize configuration
If you are curious to review the entire hipstershop-istio configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/deploy/istio
```

A key difference between the `hipstershop-default` overlay and the `hipstershop-istio` overlay is the use of the label `istio-injection=enabled` on the hipstershop namespace. Other than that, this example shows a very good use-case for Kustomize as we use bases/overlays to minimize duplication of configuration between the default and istio overlays.
```
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio-injection: enabled
  name: hipstershop
```

watch status of hipstershop deployment
```
kubectl get pods -n hipstershop -w
```

## validate istio is configured
validate that istio sidecar is deployed alongside the hipstershop microservices. we are looking for `2/2` for containers in pods vs `1/1`
```
$ k get pods -n hipstershop
NAME                                     READY   STATUS    RESTARTS   AGE
adservice-65b989f4ff-h8ng6               2/2     Running   0          4m59s
cartservice-7985d8dc68-fjkzm             2/2     Running   1          4m59s
checkoutservice-99f4578cc-p5gm2          2/2     Running   0          4m58s
currencyservice-58dfb86bd7-wvtp7         2/2     Running   0          5m
emailservice-855b866485-9vqwx            2/2     Running   0          4m59s
frontend-7db5d89c6f-ww4v2                2/2     Running   0          4m59s
loadgenerator-649cb54464-6wrls           2/2     Running   0          4m59s
paymentservice-74d7f6df45-2qb6b          2/2     Running   0          4m59s
productcatalogservice-55b48b848f-ppcj5   2/2     Running   0          4m59s
recommendationservice-7cdd594947-fr2hp   2/2     Running   0          4m59s
redis-cart-57bd646894-mn7qr              2/2     Running   0          4m59s
shippingservice-5ffbcb9645-9kwrt         2/2     Running   0          4m58s
```

run a describe on any pod to get more detail
```
$ k describe pods -n hipstershop frontend-7db5d89c6f-ww4v2
Name:         frontend-7db5d89c6f-ww4v2
Namespace:    hipstershop
Priority:     0
Node:         kind3-control-plane/172.18.0.2
Start Time:   Wed, 25 Aug 2021 19:18:04 +0000
Labels:       app=frontend
              istio.io/rev=default
              pod-template-hash=7db5d89c6f
              security.istio.io/tlsMode=istio
              service.istio.io/canonical-name=frontend
              service.istio.io/canonical-revision=v0.2.3
              version=v0.2.3
<...>
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  6m     default-scheduler  Successfully assigned hipstershop/frontend-7db5d89c6f-ww4v2 to kind3-control-plane
  Normal  Pulled     5m58s  kubelet            Container image "gcr.io/istio-enterprise/proxyv2:1.10.3" already present on machine
  Normal  Created    5m58s  kubelet            Created container istio-init
  Normal  Started    5m57s  kubelet            Started container istio-init
  Normal  Pulled     5m57s  kubelet            Container image "gcr.io/google-samples/microservices-demo/frontend:v0.2.3" already present on machine
  Normal  Created    5m57s  kubelet            Created container server
  Normal  Started    5m56s  kubelet            Started container server
  Normal  Pulled     5m56s  kubelet            Container image "gcr.io/istio-enterprise/proxyv2:1.10.3" already present on machine
  Normal  Created    5m55s  kubelet            Created container istio-proxy
  Normal  Started    5m54s  kubelet            Started container istio-proxy
```

## Exposing the hipstershop application using Istio
Deploy hipstershop virtualservice and validate
```
kubectl apply -f argo/virtualservice/istio/1-hipstershop-vs-frontend.yaml
```

## navigate to hipstershop application
get the istio-ingressgateway URL
```
kubectl get svc -n istio-system
```

output should look similar to below:
```
$ kubectl get svc -n istio-system
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                                      AGE
grafana                ClusterIP      10.3.63.168    <none>        3000/TCP                                     83m
istio-ingressgateway   LoadBalancer   10.3.217.92    172.18.3.3    15021:30839/TCP,80:30530/TCP,443:32457/TCP   84m
istiod                 ClusterIP      10.3.172.7     <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP        84m
jaeger-collector       ClusterIP      10.3.207.80    <none>        14268/TCP,14250/TCP,9411/TCP                 83m
kiali                  ClusterIP      10.3.244.91    <none>        20001/TCP,9090/TCP                           83m
prometheus             ClusterIP      10.3.109.186   <none>        9090/TCP                                     83m
tracing                ClusterIP      10.3.37.255    <none>        80/TCP,16685/TCP                             83m
zipkin                 ClusterIP      10.3.188.222   <none>        9411/TCP                                     83m
```

Navigate to the `istio-ingressgateway` EXTERNAL-IP
```
open http://172.18.3.3
```

## visualize with kiali
Navigate to the kiali dashboard to see the hipstershop app in detail

access kiali dashboard at `http://localhost:20001`
```
kubectl port-forward deployment/kiali -n istio-system 20001:20001
```

## visualize with grafana
Navigate to the grafana dashboard to see istio metrics

access grafana dashboard at `http://localhost:3000`
```
kubectl port-forward svc/grafana -n istio-system 3000:3000
```

## cleanup
to remove hipstershop application
```
kubectl delete -f argo/virtualservice/istio/1-hipstershop-vs-frontend.yaml
kubectl delete -f argo/deploy/hipstershop-istio.yaml
```

## Next Steps - Deploy bookinfo application on istio and run through gloo-mesh labs
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-mesh-singlecluster.md)