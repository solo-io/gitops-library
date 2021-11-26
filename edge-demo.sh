#!/bin/bash

LICENSE_KEY=$1
edge_version="1-9-1"

# check if cluster exists, uses current context if it does
CONTEXT=`kubectl config current-context`
if [[ ${CONTEXT} == "" ]]
  then
    echo "You do not have a curent kubernetes cluster.  Please create one."
    exit 1
  fi

# check to see if license key variable was passed through, if not prompt for key
if [[ ${LICENSE_KEY} == "" ]]
  then
    # provide license key
    echo "Please provide your Gloo Mesh Enterprise License Key:"
    read LICENSE_KEY
fi

# check OS type
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        BASE64_LICENSE_KEY=$(echo -n "${LICENSE_KEY}" | base64 -w 0)
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        BASE64_LICENSE_KEY=$(echo -n "${LICENSE_KEY}" | base64)
else
        echo unknown OS type
        exit 1
fi

# license stuff
kubectl create ns gloo-system

kubectl apply -f - <<EOF
apiVersion: v1
data:
  license-key: ${BASE64_LICENSE_KEY}
kind: Secret
metadata:
  labels:
    app: gloo
    gloo: license
  name: license
  namespace: gloo-system
type: Opaque
EOF

# install argocd 
cd argocd
./install-argocd.sh insecure 

# wait for argo cluster rollout
../tools/wait-for-rollout.sh deployment argocd-server argocd 10

# install gloo-edge without gloo-fed
cd ../gloo-edge/
kubectl apply -f argo/ee/${edge_version}/gloo-edge-ee-helm-${edge_version}.yaml

# wait for gloo-edge rollout
../tools/wait-for-rollout.sh deployment gateway gloo-system 10

# install keycloak
cd ../keycloak
kubectl apply -f argo/default/keycloak-default-12-0-4.yaml
../tools/wait-for-rollout.sh deployment keycloak default 10

# expose keycloak/argo on http
cd ../gloo-edge
kubectl apply -f argo/virtualservice/wildcard/edge-demo-http-vs.yaml
# for cloudflare edge config
#kubectl apply -f argo/virtualservice/cloudflare/edge-demo-http-vs.yaml
#kubectl apply -f argo/virtualservice/cloudflare/edge-demo-https-vs.yaml

# install cert-manager
#cd ../cert-manager
#kubectl apply -f argo/deploy/certmanager-1-6-0.yaml
#../tools/wait-for-rollout.sh deployment cert-manager cert-manager 10

# install bookinfo application
cd ../bookinfo/
kubectl apply -f argo/deploy/bookinfo-v1/default/bookinfo-v1-default.yaml
kubectl apply -f argo/deploy/bookinfo-beta/default/bookinfo-beta-default.yaml

# expose bookinfo on https
kubectl apply -f argo/virtualservice/edge/3-bookinfo-tls-multi-vs.yaml
# for cloudflare edge config
#kubectl apply -f argo/virtualservice/cloudflare-edge/3-bookinfo-tls-multi-vs.yaml

# sleep 20 seconds and set up keycloak on http
sleep 20
../keycloak/scripts/keycloak-setup-virtualservice.sh
# for cloudflare keycloak setup
#../keycloak/scripts/keycloak-setup-virtualservice-cloudflare-https.sh

# echo proxy url
echo "access the bookinfo application at: $(glooctl proxy url --port https | cut -d: -f1-2)/productpage"
echo 
echo "additional gloo edge feature demos can be found here: https://github.com/solo-io/gitops-library/blob/main/bookinfo/bookinfo-edge.md#deploy-virtualservice-with-extauth-config"
echo "Note: don't forget to cd into the bookinfo directory"