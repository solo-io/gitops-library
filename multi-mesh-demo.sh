#!/bin/bash

license_key=$1
cluster1_context="cluster1"
cluster2_context="cluster2"
mgmt_context="mgmt"
gloo_mesh_overlay="1-2-0-rc3"
meshctl_version="v1.2.0-rc3"
istio_overlay="1-11-4"

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
./install-argocd.sh default ${mgmt_context}
./install-argocd.sh default ${cluster1_context}
./install-argocd.sh default ${cluster2_context}

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
kubectl apply -f argo/deploy/${istio_overlay}/operator/istio-operator-${istio_overlay}.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/${istio_overlay}/operator/istio-operator-${istio_overlay}.yaml --context ${cluster2_context}

../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment istio-operator istio-operator 10 ${cluster2_context}

kubectl apply -f argo/deploy/${istio_overlay}/gm-istio-profiles/gm-istio-workshop-cluster1-${istio_overlay}.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/${istio_overlay}/gm-istio-profiles/gm-istio-workshop-cluster2-${istio_overlay}.yaml --context ${cluster2_context}

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
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster1-noreviews.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster2.yaml --context ${cluster2_context}

../tools/wait-for-rollout.sh deployment productpage-v1 default 10 ${cluster1_context}
../tools/wait-for-rollout.sh deployment productpage-v1 default 10 ${cluster2_context}

# -------------------- demo default istio ingressgateway + traffic shift --------------------------------------------------

# deploy default istio-ingressgateway and virtualservice for cluster1 and cluster2
kubectl apply -f argo/deploy/workshop/istio-ig/bookinfo-cluster1-istio-ig-vs.yaml --context ${cluster1_context}
kubectl apply -f argo/deploy/workshop/istio-ig/bookinfo-cluster2-istio-ig-vs.yaml --context ${cluster2_context}

# deploy virtualdestination and trafficpolicy to demonstrate trafficshift & failover
kubectl apply -f argo/deploy/workshop/istio-ig/bookinfo-mgmt-trafficshift.yaml --context ${mgmt_context}

# -------------------- demo gloo mesh gateway --------------------------------------------------

# recover reviews-v1 and reviews-v2 in cluster1
#kubectl apply -f argo/deploy/workshop/bookinfo-workshop-cluster1.yaml --context ${cluster1_context}

# deploy default gloo mesh gateway with virtualgateway, virtualhost, and routetable onto mgmt cluster only (no reviews should be available)
#kubectl apply -f argo/deploy/workshop/gmg/north-south/bookinfo-gmg-1a-simple.yaml --context ${mgmt_context}

# configure routetable to point at cluster2 services instead (all reviews should be showing)
#kubectl apply -f argo/deploy/workshop/gmg/north-south/bookinfo-gmg-1b-simple.yaml --context ${mgmt_context}

# -------------------- demo multi destination --------------------------------------------------

# run 'kubectl kustomize bookinfo/overlay/gloo-mesh-workshop/gmg/2a-multi' to view weighted destination config
#kubectl apply -f argo/deploy/workshop/gmg/north-south/bookinfo-gmg-2a-multi.yaml --context ${mgmt_context}

# shift traffic back to cluster1
#kubectl apply -f argo/deploy/workshop/gmg/north-south/bookinfo-gmg-2b-multi.yaml --context ${mgmt_context}

# allow traffic to flow to productpage on both cluster1 and cluster2
#kubectl apply -f argo/deploy/workshop/gmg/north-south/bookinfo-gmg-2c-multi.yaml --context ${mgmt_context}

# ----------------------------------------------------------------------

# deploy bombardier loadgen on istio-ingressgateway on cluster1 and cluster2
cd ../bombardier-loadgen
kubectl apply -f argo/bookinfo-loadgen-istio-ingressgateway.yaml --context ${cluster1_context}
kubectl apply -f argo/bookinfo-loadgen-istio-ingressgateway.yaml --context ${cluster2_context}

# echo port-forward commands
echo
echo "access gloo mesh dashboard:"
echo "kubectl port-forward -n gloo-mesh svc/dashboard 8090 --context ${mgmt_context}"
echo 
echo "access argocd dashboard:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443 --context <desired_context>"
echo
echo "You can use the following command to validate which cluster handles the requests:"
echo "kubectl --context ${cluster1_context} logs -l app=reviews -c istio-proxy -f"
echo "kubectl --context ${cluster2_context} logs -l app=reviews -c istio-proxy -f"
echo
echo "Continue on with bookinfo gloo-mesh-gateway lab in gitops-library git repo:"
echo "https://github.com/solo-io/gitops-library/blob/main/bookinfo/bookinfo-multicluster-gmg.md"
echo 