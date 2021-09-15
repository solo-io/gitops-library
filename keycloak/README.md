# keycloak

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd

## installing keycloak
To install keycloak on your cluster, deploy the argo app associated with the keycloak version that you want. 

For example to deploy keycloak v12.0.4 in the default namespace:
```
kubectl apply -f argo/default/keycloak-default-12-0-4.yaml
```

You can run the `wait-for-rollout.sh` script to watch deployment progress
```
../tools/wait-for-rollout.sh deployment keycloak default 10
```

## setting up keycloak
Run the script below to set up keycloak with two users `user1/password` and `user2/password`
```
./scripts/keycloak-setup.sh
```