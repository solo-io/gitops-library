# gloo-mesh-addons (enterprise features)

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- gloo-mesh - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh)
- istio - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/istio)

To use the Gloo Mesh Gateway advanced features, you need to install the Gloo Mesh addons on the clusters where Istio is installed. Gloo Mesh Gateway advanced features are deployed to the `gloo-mesh-addons` namespace with `istio-injection=enabled`
```
kubectl apply -f argo/1-1-2/gloo-mesh-ee-addons.yaml --context ${CONTEXT}
```

In our case we will be using our workshop contexts `cluster1` and `cluster2`. Output should look similar to below
```
% kubectl apply -f argo/1-1-2/gloo-mesh-ee-addons.yaml --context cluster1
application.argoproj.io/gloo-mesh-ee-addons configured

% kubectl apply -f argo/1-1-2/gloo-mesh-ee-addons.yaml --context cluster2
application.argoproj.io/gloo-mesh-ee-addons configured
```

If you run a `kubectl get pods -n gloo-mesh-addons` you should see something similar to below. Note the `2/2` indicates that an Istio sidecar has been injected into the services.
```
% k get pods -n gloo-mesh-addons --context cluster1
NAME                               READY   STATUS    RESTARTS   AGE
ext-auth-service-5f4747757-rs7cl   2/2     Running   0          90m
rate-limiter-fbdd658b-p8j55        2/2     Running   0          90m
redis-7c84bf967b-h4mxv             2/2     Running   0          90m
```

**Note:** If the pods in `gloo-mesh-addons` are listing as `1/1` then there are likely a few reasons:
- Istio is not installed on the target clusters yet, therefore not injecting the Istio sidecar
- gloo-mesh-addons were deployed before Istio was deployed, therefore the pods in the `gloo-mesh-addons` namespace must be manually bounced in order for Istio sidecar injection to occur

## Next Steps - Deploy bookinfo app
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-mesh.md)