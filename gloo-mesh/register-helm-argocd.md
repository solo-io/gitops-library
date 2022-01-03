## Register your clusters to Gloo Mesh with Helm + argocd
First we want to create a `KubernetesCluster` resouce to represent the remote cluster and store relevant data, such as the remote cluster's local domain. The `metadata.name` of the resource must match the value for `relay.cluster` in the Helm chart, and the `spec.clusterDomain` must match the local cluster domain of the Kubernetes cluster.

First for cluster1
```
kubectl apply --context mgmt -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: cluster1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF
```

Then for cluster2
```
kubectl apply --context mgmt -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: cluster2
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF
```

Since we installed Gloo Mesh by using the default self-signed certificates, you must copy the root CA certificate to a secret in the remote cluster so that the relay agent will trust the TLS certificate from the relay server. You must also copy the bootstrap token used for initial communication to the remote cluster. This token is used only to validate initial communication between the relay agent and server. After the gRPC connection is established, the relay server issues a client certificate to the relay agent to establish a mutually-authenticated TLS session.

# create gloo-mesh ns in cluster1 and cluster2
kubectl create ns gloo-mesh --context cluster1
kubectl create ns gloo-mesh --context cluster2

# ensure mgmt certs are in the remote clusters
kubectl get secret relay-root-tls-secret -n gloo-mesh --context mgmt -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context cluster1 --from-file ca.crt=ca.crt
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context cluster2 --from-file ca.crt=ca.crt
rm ca.crt

# ensure mgmt tokens are in the remote clusters
kubectl get secret relay-identity-token-secret -n gloo-mesh --context mgmt -o jsonpath='{.data.token}' | base64 -d > token
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context cluster1 --from-file token=token
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context cluster2 --from-file token=token
rm token

Grab External-IP of the enterprise-networking service in the mgmt plane as we will be using this
```
SVC=$(kubectl --context mgmt -n gloo-mesh get svc enterprise-networking -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

Deploy enterprise-agent on cluster1 using argocd
```
kubectl apply --context cluster1 -f- <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gm-enterprise-agent-cluster1
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: gloo-mesh
  source:
    repoURL: 'https://storage.googleapis.com/gloo-mesh-enterprise/enterprise-agent'
    targetRevision: 1.2.1
    chart: enterprise-agent
    helm:
      valueFiles:
        - values.yaml
      parameters:
        - name: relay.cluster
          value: cluster1
        - name: relay.serverAddress
          value: '$SVC:9900'
        - name: relay.tokenSecret.namespace
          value: gloo-mesh
        - name: authority
          value: enterprise-networking.gloo-mesh
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
    - CreateNamespace=true
    - Replace=true
    - ApplyOutOfSyncOnly=true
  project: default
EOF
```

Deploy enterprise-agent on cluster2 using argocd
```
kubectl apply --context cluster2 -f- <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gm-enterprise-agent-cluster2
  namespace: argocd
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: gloo-mesh
  source:
    repoURL: 'https://storage.googleapis.com/gloo-mesh-enterprise/enterprise-agent'
    targetRevision: 1.2.1
    chart: enterprise-agent
    helm:
      valueFiles:
        - values.yaml
      parameters:
        - name: relay.cluster
          value: cluster2
        - name: relay.serverAddress
          value: '$SVC:9900'
        - name: relay.tokenSecret.namespace
          value: gloo-mesh
        - name: authority
          value: enterprise-networking.gloo-mesh
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
    syncOptions:
    - CreateNamespace=true
    - Replace=true
    - ApplyOutOfSyncOnly=true
  project: default
EOF
```

# Verifying the registration
Verify that the relay agent pod has a status of Running
```
kubectl get pods -n gloo-mesh --context cluster1
```

Verify that the cluster is successfully identified by the management plane. This check might take a few seconds to ensure that the expected remote relay agent is now running and is connected to the relay server in the management cluster.
```
meshctl check server --kubecontext mgmt
```

Output should look similar to below:
```
% meshctl check server --kubecontext mgmt
Querying cluster. This may take a while.
Gloo Mesh Management Cluster Installation
--------------------------------------------

🟢 Gloo Mesh Pods Status
Forwarding from 127.0.0.1:9091 -> 9091

Forwarding from [::1]:9091 -> 9091

Handling connection for 9091

+----------+------------+-------------------------------+-----------------+
| CLUSTER  | REGISTERED | DASHBOARDS AND AGENTS PULLING | AGENTS PUSHING  |
+----------+------------+-------------------------------+-----------------+
| cluster1 | true       |                             2 |               1 |
+----------+------------+-------------------------------+-----------------+
| cluster2 | true       |                             2 |               1 |
+----------+------------+-------------------------------+-----------------+

🟢 Gloo Mesh Agents Connectivity

Management Configuration
---------------------------

🟢 Gloo Mesh CRD Versions

🟢 Gloo Mesh Networking Configuration Resources
```