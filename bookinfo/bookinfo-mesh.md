# bookinfo istio demo

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- Istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)


## deploy bookinfo application
Navigate to the `bookinfo` directory
```
cd bookinfo
```

Deploy the bookinfo-v1-istio app
```
kubectl apply -f argo/deploy/bookinfo-v1/istio/bookinfo-v1-mesh.yaml
```

### view kustomize configuration
If you are curious to review the entire hipstershop-istio configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/bookinfo-v1/istio/
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

watch status of bookinfo-v1 deployment
```
kubectl get pods -n bookinfo-v1 -w
```

## validate istio is configured
validate that istio sidecar is deployed alongside the hipstershop microservices. we are looking for `2/2` for containers in pods vs `1/1`
```
$ k get pods -n bookinfo-v1
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-558b8b4b76-wmnq7       2/2     Running   0          119s
productpage-v1-6987489c74-w6wt5   2/2     Running   0          119s
ratings-v1-7dc98c7588-nk7kh       2/2     Running   0          119s
reviews-v2-7d79d5bd5d-9h7j8       2/2     Running   0          119s
```

run a describe on any pod to get more detail
```
$ k describe pods -n bookinfo-v1 productpage-v1-6987489c74-w6wt5
Name:         productpage-v1-6987489c74-w6wt5
Namespace:    bookinfo-v1
Priority:     0
Node:         kind2-control-plane/172.18.0.5
Start Time:   Wed, 15 Sep 2021 18:19:55 +0000
Labels:       app=productpage
              istio.io/rev=default
              pod-template-hash=6987489c74
              security.istio.io/tlsMode=istio
              service.istio.io/canonical-name=productpage
              service.istio.io/canonical-revision=v1
              version=v1
<...>
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  2m27s  default-scheduler  Successfully assigned bookinfo-v1/productpage-v1-6987489c74-w6wt5 to kind2-control-plane
  Normal  Pulled     2m26s  kubelet            Container image "gcr.io/istio-enterprise/proxyv2:1.10.4" already present on machine
  Normal  Created    2m26s  kubelet            Created container istio-init
  Normal  Started    2m25s  kubelet            Started container istio-init
  Normal  Pulling    2m24s  kubelet            Pulling image "docker.io/istio/examples-bookinfo-productpage-v1:1.16.2"
  Normal  Pulled     114s   kubelet            Successfully pulled image "docker.io/istio/examples-bookinfo-productpage-v1:1.16.2"
  Normal  Created    113s   kubelet            Created container productpage
  Normal  Started    113s   kubelet            Started container productpage
  Normal  Pulled     113s   kubelet            Container image "gcr.io/istio-enterprise/proxyv2:1.10.4" already present on machine
  Normal  Created    113s   kubelet            Created container istio-proxy
  Normal  Started    113s   kubelet            Started container istio-proxy
```

## Exposing the bookinfo-v1 application using Istio
Deploy bookinfo-v1 virtualservice and validate
```
kubectl apply -f argo/virtualservice/istio/1-bookinfo-vs-single.yaml
```

## navigate to bookinfo-v1 application
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
to remove bookinfo-v1 application
```
kubectl delete -f argo/virtualservice/istio/1-bookinfo-vs-single.yaml
kubectl delete -f argo/deploy/bookinfo-v1/istio/bookinfo-v1-mesh.yaml
``` 

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)