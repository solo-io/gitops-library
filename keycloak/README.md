# keycloak

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)

## installing keycloak
Navigate to the `keycloak` directory
```
cd keycloak
```

To install keycloak on your cluster, deploy the argo app associated with the keycloak version that you want. 

For example to deploy keycloak v12.0.4 in the default namespace:
```
kubectl apply -f argo/app/namespace/default/keycloak-12-0-4.yaml
```

You can run the `wait-for-rollout.sh` script to watch deployment progress
```
../tools/wait-for-rollout.sh deployment keycloak default 10
```

## uninstall keycloak
```
kubectl delete -f argo/app/namespace/default/keycloak-12-0-4.yaml
```

## Next Steps - Deploy hipstershop application and expose through gloo-edge
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/hipstershop)