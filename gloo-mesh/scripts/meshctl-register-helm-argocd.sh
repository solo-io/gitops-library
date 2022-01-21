#!/bin/bash

# note that the character '_' is an invalid value if you are replacing the defaults below
mgmt_context="$1"
cluster1_context="$2"
cluster2_context="$3"
gloo_mesh_version="$4"

# register clusters to gloo mesh with helm

SVC=$(kubectl --context ${mgmt_context} -n gloo-mesh get svc enterprise-networking -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

kubectl apply --context ${mgmt_context} -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: cluster1
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

kubectl apply --context ${mgmt_context} -f- <<EOF
apiVersion: multicluster.solo.io/v1alpha1
kind: KubernetesCluster
metadata:
  name: cluster2
  namespace: gloo-mesh
spec:
  clusterDomain: cluster.local
EOF

# create gloo-mesh ns in cluster1 and cluster2
kubectl create ns gloo-mesh --context ${cluster1_context}
kubectl create ns gloo-mesh --context ${cluster2_context}

# ensure mgmt certs are in the remote clusters
kubectl get secret relay-root-tls-secret -n gloo-mesh --context ${mgmt_context} -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context ${cluster1_context} --from-file ca.crt=ca.crt
kubectl create secret generic relay-root-tls-secret -n gloo-mesh --context ${cluster2_context} --from-file ca.crt=ca.crt
rm ca.crt

# ensure mgmt tokens are in the remote clusters
kubectl get secret relay-identity-token-secret -n gloo-mesh --context ${mgmt_context} -o jsonpath='{.data.token}' | base64 -d > token
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context ${cluster1_context} --from-file token=token
kubectl create secret generic relay-identity-token-secret -n gloo-mesh --context ${cluster2_context} --from-file token=token
rm token

kubectl apply --context ${cluster1_context} -f- <<EOF
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
    targetRevision: ${gloo_mesh_version}
    chart: enterprise-agent
    helm:
      valueFiles:
        - values.yaml
      parameters:
        - name: relay.cluster
          value: cluster1
        - name: relay.serverAddress
          value: '${SVC}:9900'
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

kubectl apply --context ${cluster2_context} -f- <<EOF
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
    targetRevision: ${gloo_mesh_version}
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
