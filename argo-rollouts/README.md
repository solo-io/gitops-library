# argo rollouts

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