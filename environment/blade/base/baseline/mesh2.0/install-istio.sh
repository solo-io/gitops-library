#!/bin/bash

export ISTIO_VERSION=1.11.7
curl -L https://istio.io/downloadIstio | sh -

kubectl --context ${CLUSTER1} create ns istio-system
kubectl --context ${CLUSTER1} create ns istio-gateways

helm --kube-context=${CLUSTER1} install istio-base ./istio-1.11.7/manifests/charts/base -n istio-system

helm --kube-context=${CLUSTER1} install istio-1.11.7 ./istio-1.11.7/manifests/charts/istio-control/istio-discovery -n istio-system --values - <<EOF
revision: 1-11
global:
  meshID: mesh1
  multiCluster:
    clusterName: cluster1
  network: network1
meshConfig:
  trustDomain: cluster1
  accessLogFile: /dev/stdout
  enableAutoMtls: true
  defaultConfig:
    envoyMetricsService:
      address: gloo-mesh-agent.gloo-mesh:9977
    envoyAccessLogService:
      address: gloo-mesh-agent.gloo-mesh:9977
    proxyMetadata:
      ISTIO_META_DNS_CAPTURE: "true"
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"
      GLOO_MESH_CLUSTER_NAME: cluster1
pilot:
  env:
    PILOT_SKIP_VALIDATE_TRUST_DOMAIN: "true"
EOF

kubectl --context ${CLUSTER1} label namespace istio-gateways istio.io/rev=1-11

helm --kube-context=${CLUSTER1} install istio-ingressgateway ./istio-1.11.7/manifests/charts/gateways/istio-ingress -n istio-gateways --values - <<EOF
gateways:
  istio-ingressgateway:
    name: istio-ingressgateway
    namespace: istio-gateways
    labels:
      istio: ingressgateway
    injectionTemplate: gateway
    ports:
    - name: http2
      port: 80
      targetPort: 8080
    - name: https
      port: 443
      targetPort: 8443
EOF

helm --kube-context=${CLUSTER1} install istio-eastwestgateway ./istio-1.11.7/manifests/charts/gateways/istio-ingress -n istio-gateways --values - <<EOF
gateways:
  istio-ingressgateway:
    name: istio-eastwestgateway
    namespace: istio-gateways
    labels:
      istio: eastwestgateway
      topology.istio.io/network: network1
    injectionTemplate: gateway
    ports:
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
    env:
      ISTIO_META_ROUTER_MODE: "sni-dnat"
      ISTIO_META_REQUESTED_NETWORK_VIEW: "network1"
EOF

kubectl --context ${CLUSTER2} create ns istio-system
kubectl --context ${CLUSTER2} create ns istio-gateways

helm --kube-context=${CLUSTER2} install istio-base ./istio-1.11.7/manifests/charts/base -n istio-system

helm --kube-context=${CLUSTER2} install istio-1.11.7 ./istio-1.11.7/manifests/charts/istio-control/istio-discovery -n istio-system --values - <<EOF
revision: 1-11
global:
  meshID: mesh1
  multiCluster:
    clusterName: cluster2
  network: network1
meshConfig:
  trustDomain: cluster2
  accessLogFile: /dev/stdout
  enableAutoMtls: true
  defaultConfig:
    envoyMetricsService:
      address: gloo-mesh-agent.gloo-mesh:9977
    envoyAccessLogService:
      address: gloo-mesh-agent.gloo-mesh:9977
    proxyMetadata:
      ISTIO_META_DNS_CAPTURE: "true"
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"
      GLOO_MESH_CLUSTER_NAME: cluster2
pilot:
  env:
    PILOT_SKIP_VALIDATE_TRUST_DOMAIN: "true"
EOF

kubectl --context ${CLUSTER2} label namespace istio-gateways istio.io/rev=1-11

helm --kube-context=${CLUSTER2} install istio-ingressgateway ./istio-1.11.7/manifests/charts/gateways/istio-ingress -n istio-gateways --values - <<EOF
gateways:
  istio-ingressgateway:
    name: istio-ingressgateway
    namespace: istio-gateways
    labels:
      istio: ingressgateway
    injectionTemplate: gateway
    ports:
    - name: http2
      port: 80
      targetPort: 8080
    - name: https
      port: 443
      targetPort: 8443
EOF

helm --kube-context=${CLUSTER2} install istio-eastwestgateway ./istio-1.11.7/manifests/charts/gateways/istio-ingress -n istio-gateways --values - <<EOF
gateways:
  istio-ingressgateway:
    name: istio-eastwestgateway
    namespace: istio-gateways
    labels:
      istio: eastwestgateway
      topology.istio.io/network: network1
    injectionTemplate: gateway
    ports:
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
    env:
      ISTIO_META_ROUTER_MODE: "sni-dnat"
      ISTIO_META_REQUESTED_NETWORK_VIEW: "network1"
EOF

export ENDPOINT_HTTP_GW_CLUSTER1=$(kubectl --context ${CLUSTER1} -n istio-gateways get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].*}'):80
export ENDPOINT_HTTPS_GW_CLUSTER1=$(kubectl --context ${CLUSTER1} -n istio-gateways get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].*}'):443
export HOST_GW_CLUSTER1=$(echo ${ENDPOINT_HTTP_GW_CLUSTER1} | cut -d: -f1)

