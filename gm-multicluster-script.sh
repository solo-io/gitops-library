#!/bin/bash

LICENSE_KEY=$1

# check to see if license key variable was passed through, if not prompt for key
if [[ ${LICENSE_KEY} == "" ]]
  then
    # provide license key
    echo "Please provide your Gloo Mesh Enterprise License Key:"
    read LICENSE_KEY
fi

# sed command to replace license key  
sed -i -e "s/<INSERT_LICENSE_KEY_HERE>/${LICENSE_KEY}/g" gloo-mesh/argo/1-1-2/gloo-mesh-ee-helm.yaml

# install argocd on mgmt, cluster1, and cluster2
cd argocd
./install-argocd.sh mgmt
./install-argocd.sh cluster1
./install-argocd.sh cluster2

# install gloo-mesh on mgmt
cd ../gloo-mesh/
kubectl apply -f argo/1-1-2/gloo-mesh-ee-helm.yaml --context mgmt

../tools/wait-for-rollout.sh deployment enterprise-networking gloo-mesh 10 mgmt

# register clusters
./scripts/meshctl-register.sh mgmt cluster1
./scripts/meshctl-register.sh mgmt cluster2

# install istio on cluster1 and cluster2
cd ../istio
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml --context cluster1
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml --context cluster2

../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 cluster1
../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 cluster2

kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-cluster1-1-10-4.yaml --context cluster1
kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-cluster2-1-10-4.yaml --context cluster2

../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster1
../tools/wait-for-rollout.sh deployment istiod istio-system 10 cluster2

# set strict mtls
kubectl apply -f argo/deploy/mtls/strict-mtls.yaml --context cluster1
kubectl apply -f argo/deploy/mtls/strict-mtls.yaml --context cluster2

# deploy gloo-mesh dataplane addons
cd ../gloo-mesh/
kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context cluster1
kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context cluster2

../tools/wait-for-rollout.sh deployment ext-auth-service gloo-mesh-addons 10 cluster1
../tools/wait-for-rollout.sh deployment ext-auth-service gloo-mesh-addons 10 cluster2

# deploy gloo-mesh controlplane addons (accesspolicy)
kubectl apply -f argo/gloo-mesh-controlplane-config.yaml --context mgmt

# create virtualmesh
kubectl apply -f argo/gloo-mesh-virtualmesh-rbac-enabled.yaml --context mgmt

# deploy bookinfo app into cluster1 and cluster2
cd ../bookinfo/
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster1-noreviews.yaml --context cluster1
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster2.yaml --context cluster2

../tools/wait-for-rollout.sh deployment productpage-v1 default 10 cluster1
../tools/wait-for-rollout.sh deployment productpage-v1 default 10 cluster2

# deploy virtualdestination and trafficpolicy to demonstrate trafficshift & failover
kubectl apply -f argo/deploy/workshop/bookinfo-cluster1-cluster2-trafficshift.yaml --context mgmt

# echo port-forward commands
echo
echo "access gloo mesh dashboard:"
echo "kubectl port-forward -n gloo-mesh svc/dashboard 8090 --context mgmt"
echo 
echo "access argocd dashboard:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443 --context <desired_context>"