# Istio
This guide will walk a user through deploying Solo.io fully supported (N-4) builds of upstream Istio, however the process is still completely applicable to deploying using the community based Istio images as well.

## Note for Multicluster Labs
In order to continue forward with the Multicluster labs, you will need to run through these lab instructions for both `cluster1` and for `cluster2`. It is useful to add `--context <cluster>` to specify which cluster to deploy to

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)

## installing gloo mesh istio
Navigate to the `istio` directory
```
cd istio
```

Deploy the istio-operator app with the specified version
```
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml --context <cluster>
```

You can run the `wait-for-rollout.sh` script to watch deployment progress. Be sure to replace the `<context>` with the right cluster, if not provided it will assume the `current-context`
```
../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 <cluster>
```

Output should look similar to below:
```
$ ../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10
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

For our tutorial we will be using commercially supported Solo.io builds of Istio and the with the Istio profile that we use in our Gloo Mesh workshop at [workshops.solo.io](workshops.solo.io)

### view kustomize configuration
If you are curious to review the entire istio configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/1-10-4/gm-istio-profiles/workshop/cluster1/
kubectl kustomize overlay/1-10-4/gm-istio-profiles/workshop/cluster2/
```

Output should look similar to below. Note that there are seperate overlays for `cluster1` and `cluster2` that you can view
```
% kubectl kustomize overlay/1-10-4/gm-istio-profiles/workshop/cluster1/
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio-default-profile
  namespace: istio-system
spec:
  components:
    ingressGateways:
    - enabled: true
      k8s:
        env:
        - name: ISTIO_META_ROUTER_MODE
          value: sni-dnat
        - name: ISTIO_META_REQUESTED_NETWORK_VIEW
          value: network1
        service:
          ports:
          - name: http2
            port: 80
            targetPort: 8080
          - name: https
            port: 443
            targetPort: 8443
          - name: tcp-status-port
            port: 15021
            targetPort: 15021
          - name: tls
            port: 15443
            targetPort: 15443
          - name: tcp-istiod
            port: 15012
            targetPort: 15012
          - name: tcp-webhook
            port: 15017
            targetPort: 15017
      label:
        topology.istio.io/network: network1
      name: istio-ingressgateway
    pilot:
      k8s:
        env:
        - name: PILOT_SKIP_VALIDATE_TRUST_DOMAIN
          value: "true"
  hub: gcr.io/istio-enterprise
  meshConfig:
    accessLogFile: /dev/stdout
    defaultConfig:
      envoyAccessLogService:
        address: enterprise-agent.gloo-mesh:9977
      envoyMetricsService:
        address: enterprise-agent.gloo-mesh:9977
      proxyMetadata:
        GLOO_MESH_CLUSTER_NAME: cluster1
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
        ISTIO_META_DNS_CAPTURE: "true"
    enableAutoMtls: true
    trustDomain: cluster1
  profile: default
  tag: 1.10.4
  values:
    global:
      meshID: mesh1
      meshNetworks:
        network1:
          endpoints:
          - fromRegistry: cluster1
          gateways:
          - port: 443
            registryServiceName: istio-ingressgateway.istio-system.svc.cluster.local
      multiCluster:
        clusterName: cluster1
      network: network1
  ```

### Deploy istio on cluster1
```
kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-cluster1-1-10-4.yaml --context cluster1
```

You can run the `wait-for-rollout.sh` script to watch deployment progress of istiod
```
../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster1
```

Output should look similar to below
```
$ ../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster1
Waiting 10 seconds for deployment istiod to come up.
Waiting for deployment "istiod" rollout to finish: 0 of 1 updated replicas are available...
deployment "istiod" successfully rolled out
Waiting 20 seconds for deployment istiod to come up.
deployment "istiod" successfully rolled out
```

check to see if istio-ingressgateway also was deployed
```
kubectl get pods -n istio-system --context cluster1
```

Output should look similar to below
```
$ kubectl get pods -n istio-system --context cluster1
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-6486dd4ffc-2fjzg   1/1     Running   0          19s
istiod-7f5668c8f7-dm9j6                 1/1     Running   0          30s
```

### Deploy istio on cluster2
```
kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-cluster2-1-10-4.yaml --context cluster2
```

You can run the `wait-for-rollout.sh` script to watch deployment progress of istiod
```
../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster2
```

Output should look similar to below
```
$ ../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster2
Waiting 10 seconds for deployment istiod to come up.
Waiting for deployment "istiod" rollout to finish: 0 of 1 updated replicas are available...
deployment "istiod" successfully rolled out
Waiting 20 seconds for deployment istiod to come up.
deployment "istiod" successfully rolled out
```

check to see if istio-ingressgateway also was deployed
```
kubectl get pods -n istio-system --context cluster2
```

Output should look similar to below
```
$ kubectl get pods -n istio-system --context cluster1
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-6486dd4ffc-2fjzg   1/1     Running   0          19s
istiod-7f5668c8f7-dm9j6                 1/1     Running   0          30s
```

### (optional) set to STRICT mtls
By default, Istio deploys with mtls set to `PERMISSIVE` if not explicitly stated. If your desire is to enforce `STRICT` mtls across the entire mesh, you can set the `spec.mtls.mode: STRICT` in the `PeerAuthentication` custom resource. You can run the command below to view an example
```
kubectl kustomize overlay/mtls/strict
```

Output should look similar to below. Deploying this config will set the mtls mode to `STRICT` across the entire cluster. Note that it is possible to set mtls `STRICT` on a per namespace basis as well.
```
% kubectl kustomize overlay/mtls/strict
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

Deploy the argo application that contains the config for strict mtls on the desired clusters. In our case we would replace the context with `cluster1` and `cluster2`
```
kubectl create -f argo/deploy/mtls/strict-mtls.yaml --context <cluster>
```

### (optional) install istio-addons
istio-addons provides observability tools (prometheus, grafana, jaeger, kiali) to use for test/dev in non-production environments

Deploy the istio-addons app
```
kubectl apply -f argo/deploy/addons/istio-addons.yaml --context <cluster>
```

check to see if istio-addons are deployed
```
kubectl get pods -n istio-system --context <cluster>
``` 

Output should look similar to below
```
$ kubectl get pods -n istio-system --context cluster1
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
kubectl port-forward svc/grafana -n istio-system 3000:3000 --context <cluster>
```

access kiali dashboard at `http://localhost:20001`
```
kubectl port-forward deployment/kiali -n istio-system 20001:20001 --context <cluster>
```

access jaeger dashboard at `http://localhost:16686`
```
kubectl port-forward svc/tracing -n istio-system 16686:80 --context <cluster>
```

access prometheus dashboard at `http://localhost:9090`
```
kubectl port-forward svc/prometheus -n istio-system 9090:9090 --context <cluster>
```

## Next Steps (single cluster) - Deploy hipstershop application and expose through istio
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/hipstershop/hipstershop-mesh.md)

## Next Steps (single cluster) - Deploy bookinfo application and expose through istio 
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/bookinfo/bookinfo-mesh-singlecluster.md)

## Next Steps (multi cluster) - Deploy gloo mesh addons
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-mesh/gloo-mesh-addons.md)