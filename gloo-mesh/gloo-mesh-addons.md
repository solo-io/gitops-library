# gloo-mesh-addons (enterprise features)

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- gloo-mesh - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh)
- istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)


## gloo-mesh dataplane addons
To use the Gloo Mesh Gateway advanced features, you need to install the Gloo Mesh addons on the clusters where Istio is installed. Gloo Mesh Gateway advanced features are deployed to the `gloo-mesh-addons` namespace with `istio-injection=enabled`
```
kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context ${CONTEXT}
```

In our case we will be using our workshop contexts `cluster1` and `cluster2`. Output should look similar to below
```
% kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context cluster1
application.argoproj.io/gloo-mesh-dataplane-addons-meta created

% kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context cluster2
application.argoproj.io/gloo-mesh-dataplane-addons-meta created
```

If you run a `kubectl get pods -n gloo-mesh-addons --context cluster1` you should see something similar to below. Note the `2/2` indicates that an Istio sidecar has been injected into the services.
```
% kubectl get pods -n gloo-mesh-addons --context cluster1
NAME                               READY   STATUS    RESTARTS   AGE
ext-auth-service-5f4747757-7vhds   2/2     Running   0          38s
rate-limiter-fbdd658b-7zs7h        2/2     Running   0          38s
redis-7c84bf967b-fcnzt             2/2     Running   0          38s
```

**Note:** If the pods in `gloo-mesh-addons` are listing as `1/1` then there are likely a few reasons:
- Istio is not installed on the target clusters yet, therefore not injecting the Istio sidecar
- gloo-mesh-addons were deployed before Istio was deployed, therefore the pods in the `gloo-mesh-addons` namespace must be manually bounced in order for Istio sidecar injection to occur

## gloo-mesh controlplane addons
We need to create an `AccessPolicy` so that the Istio Ingress Gateways can communicate with the addons as well as the addons to communicate together. For Gitops, instead of creating a 1:1 mapping for AccessPolicy to Argo Application, an overlay has been created called `controlplane-addons` which can then house one to many access policies or other configuration related to the controlplane. An associated Argo Application has been created referencing this overlay

To deploy the controlplane addons run the command below
```
% kubectl apply -f argo/gloo-mesh-controlplane-addons.yaml --context mgmt
```

To validate your accesspolicy you can run `kubectl get accesspolicy -n gloo-mesh --context mgmt`
```
% kubectl get accesspolicy -A --context mgmt
NAMESPACE   NAME                               AGE
gloo-mesh   controlplane-addons-accesspolicy   43s
```

## Next Steps for Single and Multi Cluster Labs - Deploy Istio
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)

