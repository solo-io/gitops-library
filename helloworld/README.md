# helloworld argo rollouts

deploy helloworld argo rollout
```
kubectl apply -f argo/app/argo-rollout/namespace/default/helloworld-rollout.yaml
```

observe rollout
```
% kubectl get ro
NAME         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE
helloworld   1         1         1            1
```

watch rollout (in another terminal is recommended)
```
kubectl argo rollouts get rollout helloworld --watch   
```

update rollout image to v2
```
kubectl argo rollouts set image helloworld \
  helloworld=docker.io/istio/examples-helloworld-v2
```

visualize trafficshift in virtualservice

in another tab you can watch your virtualservice to observe traffic shifting. You should see the weights shift from 100% stable incrementally to 100% canary, and then result in setting the canary to the stable tag once complete.
```
kubectl get virtualservice helloworld-vsvc -o yaml -w
```

## if you need to abort rollout
```
kubectl argo rollouts abort helloworld
```

## revert to desired state to complete abort
```
kubectl argo rollouts set image helloworld \
  helloworld=docker.io/istio/examples-helloworld-v1
```