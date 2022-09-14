# Installing with Helm

## Istio and Istio Ingress Gateways

First of all, let's Download the Istio release 1.13.4:
```bash
export ISTIO_VERSION=1.13.4
curl -L https://istio.io/downloadIstio | sh -
```

Then, you need to create the `istio-system` and the `istio-gateways` namespaces on the first cluster.
```bash
kubectl create ns istio-system
kubectl create ns istio-gateways
```

Now, let's deploy the Istio control plane on the first cluster:
```bash
helm upgrade --install istio-base ./istio-1.13.4/manifests/charts/base -n istio-system --set defaultRevision=1-13

helm upgrade --install istio-1.13.4 ./istio-1.13.4/manifests/charts/istio-control/istio-discovery -n istio-system --values istiod-values.yaml
```

After that, you can deploy the gateway(s):
```bash
kubectl label namespace istio-gateways istio.io/rev=1-13

helm upgrade --install istio-ingressgateway ./istio-1.13.4/manifests/charts/gateways/istio-ingress -n istio-gateways --values istio-ingressgateway-values.yaml

helm upgrade --install istio-eastwestgateway ./istio-1.13.4/manifests/charts/gateways/istio-ingress -n istio-gateways --values istio-eastwestgateway-values.yaml
```

As you can see, we deploy the control plane (istiod) in the `istio-system` and gateway(s) in the `istio-gateways` namespace.

One gateway will be used for ingress traffic while the other one will be used for cross cluster communications. It's not mandatory to use separate gateways, but it's a best practice.

Run the following command until all the Istio Pods are ready:
```bash
kubectl get pods -n istio-system && kubectl get pods -n istio-gateways
```

When they are ready, you should get this output:
```
NAME                      READY   STATUS    RESTARTS   AGE
istiod-5c669bcf6f-2hn6c   1/1     Running   0          3m7s
NAME                                     READY   STATUS    RESTARTS   AGE
istio-eastwestgateway-77f79cdb47-f4r7k   1/1     Running   0          2m53s
istio-ingressgateway-744fcf4fb-5dc7q     1/1     Running   0          2m44s
```
