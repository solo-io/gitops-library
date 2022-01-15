# bookinfo argo rollouts

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- Istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)

# install argo-rollouts cli plugin
```
brew install argoproj/tap/kubectl-argo-rollouts
```

## deploy argo rollouts
Navigate to the `argo-rollouts` directory
```
cd argo-rollouts
```

deploy argo rollouts to your cluster
```
kubectl apply -f argo/argo-rollout-1.1.1.yaml
```

Check to see if argo rollouts is deployed:
```
kubectl get pods -n argo-rollouts
NAME                            READY   STATUS    RESTARTS   AGE
argo-rollouts-6bc46bcfd-47plj   1/1     Running   0          125m
```

# label default namespace for istio injection
```
kubectl label namespace default istio-injection=enabled
```

## deploy bookinfo application
Navigate to the `bookinfo` directory
```
cd ../bookinfo
```

## deploy rollout enabled bookinfo app
```
kubectl apply -f argo/app/namespace/default/mesh/istio-rollout.yaml
```

### view kustomize configuration
If you are curious to review the entire bookinfo rollouts configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/app/rollout/
```

watch status of bookinfo rollout deployment
```
kubectl get rollouts
```

output should look similar to below:
```
% kubectl get rollouts
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE
details-rollout       3         3         3            3
productpage-rollout   3         3         3            3
ratings-rollout       3         3         3            3
reviews-rollout       3         3         3            3
```

# visualize rollout in another terminal
```
kubectl argo rollouts get rollout productpage-rollout --watch              
```

# deploy bombardier to generate load on our istio ingress gateway
```
kubectl apply -f ../bombardier-loadgen/argo/bookinfo-loadgen-istio-ingressgateway.yaml
```

# watch logs of bombardier
```
kubectl logs $(kubectl get pods -n istio-system | grep bombardier | awk '{ print $1 }' ) -n istio-system -f
```

# update rollout
```
kubectl argo rollouts set image productpage-rollout \
  productpage-rollout=ably77/bookinfo-canary:2
```

# visualize rollout status
navigate back to terminal where you are watching the rollout, you should see an `AnalysisRun` happening

Output should look similar to below when complete:
```
Name:            productpage-rollout
Namespace:       default
Status:          ✔ Healthy
Strategy:        Canary
  Step:          18/18
  SetWeight:     100
  ActualWeight:  100
Images:          ably77/bookinfo-canary:2 (stable)
Replicas:
  Desired:       1
  Current:       1
  Updated:       1
  Ready:         1
  Available:     1

NAME                                             KIND         STATUS        AGE    INFO
⟳ productpage-rollout                            Rollout      ✔ Healthy     9m9s   
├──# revision:2                                                                    
│  ├──⧉ productpage-rollout-5bdfb899b8           ReplicaSet   ✔ Healthy     6m36s  stable
│  │  └──□ productpage-rollout-5bdfb899b8-pqptv  Pod          ✔ Running     6m36s  ready:2/2
│  └──α productpage-rollout-5bdfb899b8-2         AnalysisRun  ✔ Successful  6m34s  ✔ 7
└──# revision:1                                                                    
   └──⧉ productpage-rollout-67c4ccf6b7           ReplicaSet   • ScaledDown  9m8s
```

# visualize trafficshift in virtualservice
in another tab you can watch your virtualservice to observe traffic shifting. You should see the weights shift from 100% stable incrementally to 100% canary, and then result in setting the canary to the stable tag once complete.
```
kubectl get virtualservice productpage-rollout-vsvc -o yaml -w
```

# Visualize in browser
Navigate to the bookinfo application in your browser
```
echo "http://$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].*}')/productpage"
```

When complete, you should see that the title of the productpage has changed to say `The Comedy of Errors - Hello Version 2 (canary)`
![](https://github.com/solo-io/gitops-library/blob/main/images/rollout1.png)

## if you need to abort rollout
```
kubectl argo rollouts abort productpage-rollout
```

## revert to desired state to complete abort
```
kubectl argo rollouts set image productpage-rollout \
  productpage-rollout=ably77/bookinfo-canary:1
```

# Bonus: simulate failure and rollback
If you follow the instructions without deploying the bombardier load generator, can you give a guess why?

Answer:
The `AnalysisRun` will fail because the test to pass 90% success connections is unsuccessful. The point of the load generator is to provide a consistent stream of requests so that the AnalysisRun can perform off of "real data"


## Bonus #2 - do a similar exercise with reviews app

Update rollout to v2 reviews (black stars) gradually
```
kubectl argo rollouts set image reviews-rollout \
  reviews=docker.io/istio/examples-bookinfo-reviews-v2:1.16.2
```

see `reviews-rollout.yaml` for more details:
```
steps:
      - setWeight: 20
      - pause: {}
      - setWeight: 40
      - pause: {duration: 10}
      - setWeight: 60
      - pause: {duration: 10}
      - setWeight: 80
      - pause: {duration: 10}
```

visualize rollout in another terminal
```
kubectl argo rollouts get rollout reviews-rollout --watch              
```

update rollout to v3 reviews (red stars) gradually
```
kubectl argo rollouts set image reviews-rollout \
  reviews=docker.io/istio/examples-bookinfo-reviews-v3:1.16.2
```

