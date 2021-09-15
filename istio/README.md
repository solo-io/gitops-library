# Istio

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)

This guide will walk a user through deploying Solo.io fully supported (N-4) builds of upstream Istio, however the process is still completely applicable to deploying using the community based Istio images as well.

## installing gloo mesh istio
Navigate to the `istio` directory
```
cd istio
```

Deploy the istio-operator app with the specified version
```
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml
```

You can run the `wait-for-rollout.sh` script to watch deployment progress
```
../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10
```

Output should look similar to below:
```
$ ../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10
No context specified. Using default context of cluster1
Waiting 10 seconds for deployment istio-operator to come up.
Error from server (NotFound): namespaces "istio-operator" not found
Waiting 20 seconds for deployment istio-operator to come up.
Error from server (NotFound): namespaces "istio-operator" not found
Waiting 30 seconds for deployment istio-operator to come up.
<...>
Waiting for deployment "istio-operator" rollout to finish: 0 of 1 updated replicas are available...
deployment "istio-operator" successfully rolled out
```

### Deploy your desired profile of Istio
If you navigate to the `argo/deploy/<version>/` directory you will see many options and profiles of Istio that you can deploy. For example, this guide uses the `gm-istio-profiles` which will use Solo.io built and supported (N-4) Istio images, whereas the `oss-profiles` will use the default community images. Nested in each option are overlays that configure differing [Istio Configuration Profiles](https://istio.io/latest/docs/setup/additional-setup/config-profiles/) 

For our tutorial we will be using commercially supported Solo.io builds of Istio and the `default` Istio profile

Now deploy istio
```
kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-default-1-10-4.yaml
```

You can run the `wait-for-rollout.sh` script to watch deployment progress of istiod
```
../tools/wait-for-rollout.sh deployment istiod istio-system 10
```

Output should look similar to below
```
$ ../tools/wait-for-rollout.sh deployment istiod istio-system 10
No context specified. Using default context of cluster1
Waiting 10 seconds for deployment istiod to come up.
Waiting for deployment "istiod" rollout to finish: 0 of 1 updated replicas are available...
deployment "istiod" successfully rolled out
Waiting 20 seconds for deployment istiod to come up.
deployment "istiod" successfully rolled out
```

check to see if istio-ingressgateway also was deployed
```
kubectl get pods -n istio-system
```

Output should look similar to below
```
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-6486dd4ffc-2fjzg   1/1     Running   0          19s
istiod-7f5668c8f7-dm9j6                 1/1     Running   0          30s
```

### install istio-addons
istio-addons provides observability tools (prometheus, grafana, jaeger, kiali) to use for test/dev in non-production environments

Deploy the istio-addons app
```
kubectl apply -f argo/deploy/addons/istio-addons.yaml
```

check to see if istio-addons are deployed
```
kubectl get pods -n istio-system
```

Output should look similar to below
```
$ kubectl get pods -n istio-system
NAME                                    READY   STATUS    RESTARTS   AGE
grafana-789c84856f-wdjfw                1/1     Running   0          38m
istio-ingressgateway-6486dd4ffc-h2nxv   1/1     Running   0          46m
istiod-7f5668c8f7-zdm2d                 1/1     Running   0          46m
jaeger-7f8cd55b4c-852qr                 1/1     Running   0          38m
kiali-6457c5bbdc-vpjsh                  1/1     Running   0          38m
prometheus-84446c5697-5h2w2             2/2     Running   0          38m
```

## port-forward commands
access grafana dashboard at `http://localhost:3000`
```
kubectl port-forward svc/grafana -n istio-system 3000:3000
```

access kiali dashboard at `http://localhost:20001`
```
kubectl port-forward deployment/kiali -n istio-system 20001:20001
```

access jaeger dashboard at `http://localhost:16686`
```
kubectl port-forward svc/tracing -n istio-system 16686:80
```

access prometheus dashboard at `http://localhost:9090`
```
kubectl port-forward svc/prometheus -n istio-system 9090:9090
```

## Next Steps - Deploy hipstershop application and expose through istio
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/hipstershop)