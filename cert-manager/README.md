# cert-manager

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)

## installing cert-manager
Navigate to the `cert-manager` directory
```
cd cert-manager
```

To install cert-manager on your cluster, deploy the argo app associated with the cert-manager version that you want. 

For example to deploy cert-manager v12.0.4 in the default namespace:
```
kubectl apply -f argo/deploy/certmanager-1-6-0.yaml
```

You can run the `wait-for-rollout.sh` script to watch deployment progress
```
../tools/wait-for-rollout.sh deployment cert-manager default 10
```

## uninstall cert-manager
```
kubectl delete -f argo/deploy/certmanager-1-6-0.yaml
```