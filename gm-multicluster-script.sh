#!/bin/bash

license_key=$1
cluster1_context="cluster1"
cluster2_context="cluster2"
mgmt_context="mgmt"

# check to see if mgmt_context exists
if [[ $(kubectl config get-contexts | grep ${mgmt_context}) = "" ]]
  then
    echo "You do not have a kubernetes cluster named ${mgmt_context}.  Please create one."
    exit 1
fi

# check to see if cluster1_context exists
if [[ $(kubectl config get-contexts | grep ${cluster1_context}) = "" ]]
  then
    echo "You do not have a kubernetes cluster named ${cluster1_context}.  Please create one."
    exit 1
fi

# check to see if cluster2_context exists
if [[ $(kubectl config get-contexts | grep ${cluster2_context}) = "" ]]
  then
    echo "You do not have a kubernetes cluster named ${cluster2_context}.  Please create one."
    exit 1
fi

# check to see if license key variable was passed through, if not prompt for key
if [[ ${license_key} == "" ]]
  then
    # provide license key
    echo "Please provide your Gloo Mesh Enterprise License Key:"
    read license_key
fi

# sed command to replace license key  
sed -i -e "s/<INSERT_LICENSE_KEY_HERE>/${license_key}/g" gloo-mesh/argo/1-1-2/gloo-mesh-ee-helm.yaml

# install argocd on mgmt, ${cluster1_context}, and ${cluster2_context}
cd argocd
./install-argocd.sh ${mgmt_context}
./install-argocd.sh ${cluster1_context}
./install-argocd.sh ${cluster2_context}

# install gloo-mesh on mgmt
cd ../gloo-mesh/
kubectl apply -f argo/1-1-2/gloo-mesh-ee-helm.yaml --context ${mgmt_context}

../tools/wait-for-rollout.sh deployment enterprise-networking gloo-mesh 10 ${mgmt_context}

# register clusters
./scripts/meshctl-register.sh ${mgmt_context} ${cluster1_context}
./scripts/meshctl-register.sh ${mgmt_context} ${cluster2_context}

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

# deploy gloo-mesh dataplane addons
cd ../gloo-mesh/
kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context ${cluster1_context}
kubectl apply -f argo/1-1-2/gloo-mesh-dataplane-addons.yaml --context ${cluster2_context}

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