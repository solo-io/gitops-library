#!/bin/bash

license_key=$1
cluster1_context="cluster1"
cluster2_context="cluster2"
mgmt_context="mgmt"
gloo_mesh_overlay="1-2-0-rc2"
meshctl_version="1.2.0-rc2"

# check to see if defined contexts exist
if [[ $(kubectl config get-contexts | grep ${mgmt_context}) == "" ]] || [[ $(kubectl config get-contexts | grep ${cluster1_context}) == "" ]] || [[ $(kubectl config get-contexts | grep ${cluster2_context}) == "" ]]; then
  echo "Check Failed: Either mgmt, cluster1, and cluster2 contexts do not exist. Please check to see if you have three clusters available"
  echo "Run 'kubectl config get-contexts' to see currently available contexts. If the clusters are available, please make sure that they are named correctly. Default is mgmt, cluster1, and cluster2"
  exit 1;
fi

# check to see if license key variable was passed through, if not prompt for key
if [[ ${license_key} == "" ]]
  then
    # provide license key
    echo "Please provide your Gloo Mesh Enterprise License Key:"
    read license_key
fi

# sed command to replace license key  
sed -i -e "s/<INSERT_LICENSE_KEY_HERE>/${license_key}/g" gloo-mesh/argo/${gloo_mesh_overlay}/gloo-mesh-ee-helm.yaml

# install argocd on mgmt, ${cluster1_context}, and ${cluster2_context}
cd argocd
./install-argocd.sh ${mgmt_context}
./install-argocd.sh ${cluster1_context}
./install-argocd.sh ${cluster2_context}

# wait for argo cluster rollout
../tools/wait-for-rollout.sh deployment argocd-server argocd 10 ${mgmt_context}
../tools/wait-for-rollout.sh deployment argocd-server argocd 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment argocd-server argocd 10 ${cluster2_context}

# install gloo-mesh on mgmt
cd ../gloo-mesh/
kubectl apply -f argo/${gloo_mesh_overlay}/gloo-mesh-ee-helm.yaml --context ${mgmt_context}

../tools/wait-for-rollout.sh deployment enterprise-networking gloo-mesh 10 ${mgmt_context}

# install istio on ${cluster1_context} and ${cluster2_context}
cd ../istio
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/1-10-4/operator/istio-operator-1-10-4.yaml --context ${cluster2_context}

../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 ${cluster2_context}

kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-${cluster1_context}-1-10-4.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/1-10-4/gm-istio-profiles/gm-istio-workshop-${cluster2_context}-1-10-4.yaml --context ${cluster2_context}

../tools/wait-for-rollout.sh deployment istiod istio-system 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment istiod istio-system 10 ${cluster2_context}

# set strict mtls
kubectl apply -f argo/deploy/mtls/strict-mtls.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/mtls/strict-mtls.yaml --context ${cluster2_context}

# register clusters to gloo mesh
cd ../gloo-mesh/
./scripts/meshctl-register.sh ${mgmt_context} ${cluster1_context} ${meshctl_version}
./scripts/meshctl-register.sh ${mgmt_context} ${cluster2_context} ${meshctl_version}

# deploy gloo-mesh dataplane addons
kubectl apply -f argo/${gloo_mesh_overlay}/gloo-mesh-dataplane-addons.yaml --context ${cluster1_context}
kubectl apply -f argo/${gloo_mesh_overlay}/gloo-mesh-dataplane-addons.yaml --context ${cluster2_context}

../tools/wait-for-rollout.sh deployment ext-auth-service gloo-mesh-addons 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment ext-auth-service gloo-mesh-addons 10 ${cluster2_context}

# deploy gloo-mesh controlplane addons (accesspolicy)
kubectl apply -f argo/gloo-mesh-controlplane-config.yaml --context ${mgmt_context}

# create virtualmesh
kubectl apply -f argo/gloo-mesh-virtualmesh-rbac-enabled.yaml --context ${mgmt_context}

# deploy bookinfo app into ${cluster1_context} and ${cluster2_context}
cd ../bookinfo/
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-${cluster1_context}-noreviews.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-${cluster2_context}.yaml --context ${cluster2_context}

../tools/wait-for-rollout.sh deployment productpage-v1 default 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment productpage-v1 default 10 ${cluster2_context}

# deploy virtualdestination and trafficpolicy to demonstrate trafficshift & failover
kubectl apply -f argo/deploy/workshop/bookinfo-${cluster1_context}-${cluster2_context}-trafficshift.yaml --context ${mgmt_context}

# echo port-forward commands
echo
echo "access gloo mesh dashboard:"
echo "kubectl port-forward -n gloo-mesh svc/dashboard 8090 --context ${mgmt_context}"
echo 
echo "access argocd dashboard:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443 --context <desired_context>"
echo
echo "You can use the following command to validate that the requests are handled by ${cluster2_context}"
echo "kubectl --context ${cluster2_context} logs -l app=reviews -c istio-proxy -f"