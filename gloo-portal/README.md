# gloo-portal

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- gloo-edge deployed in cluster [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-edge)

## installing gloo portal
Navigate to the `gloo-portal` directory
```
cd gloo-portal
```

Using your favorite text editor, replace the helm value `license_key: <INSERT_LICENSE_KEY_HERE>` in the `argo/deploy/gloo-portal-helm.yaml` manifest
```
helm:
      values: |
        glooEdge:
          enabled: true
        istio:
          enabled: false
        glooMesh:
          enabled: false
        licenseKey: 
          value: <INSERT_LICENSE_KEY_HERE>
```

Deploy the `gloo-portal-helm.yaml` app
```
kubectl apply -f argo/deploy/gloo-portal-helm.yaml
```

You can run the `wait-for-rollout.sh` script to watch deployment progress
```
../tools/wait-for-rollout.sh deployment gloo-portal-admin-server gloo-portal 10
```

Output should look similar to below:
```
$ ../tools/wait-for-rollout.sh deployment gloo-portal-admin-server gloo-portal 10
No context specified. Using current context of cluster1
Waiting 10 seconds for deployment gloo-portal-admin-server to come up.
Waiting for deployment "gloo-portal-admin-server" rollout to finish: 0 of 1 updated replicas are available...
deployment "gloo-portal-admin-server" successfully rolled out
Waiting 20 seconds for deployment gloo-portal-admin-server to come up.
deployment "gloo-portal-admin-server" successfully rolled out
```

## access admin UI of Gloo Portal with port-forwarding
access gloo-portal dashboard at `http://localhost:8000`
```
kubectl port-forward -n gloo-portal svc/gloo-portal-admin-server 8000:8080
```

## Next Steps - deploy keycloak
If you plan to follow along with the guides, it is recommended to install the keycloak argo application as well as we will be using this later.
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/keycloak)

## Next Steps #2 - deploy petstore gloo-portal demo app
After keycloak is deployed, you can follow the petstore gloo-portal demo lab to publish your first api through gloo-portal
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/petstore)

