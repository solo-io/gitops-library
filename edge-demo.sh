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
./install-argocd.sh insecure-rootpath

# wait for argo cluster rollout
../tools/wait-for-rollout.sh deployment argocd-server argocd 10

# expose argocd at argocd.example.com
kubectl apply -f argo/config/domain/example.com/argo-http-vs.yaml

# install gloo-edge without gloo-fed
cd ../gloo-edge/
kubectl apply -f argo/ee/${edge_version}/gloo-edge-ee-helm-${edge_version}.yaml

# wait for gloo-edge rollout
../tools/wait-for-rollout.sh deployment gateway gloo-system 10

# install keycloak
cd ../keycloak
kubectl apply -f argo/app/namespace/default/keycloak-12-0-4.yaml
../tools/wait-for-rollout.sh deployment keycloak default 10

# expose keycloak on http
kubectl apply -f argo/config/domain/wildcard/keycloak-http-vs.yaml

# install bookinfo application
cd ../bookinfo/
kubectl apply -f argo/app/namespace/bookinfo-v1/non-mesh/1.2.a-reviews-v1-v2.yaml
kubectl apply -f argo/app/namespace/bookinfo-v2/non-mesh/1.3.a-reviews-all.yaml
../tools/wait-for-rollout.sh deployment productpage-v1 bookinfo-v1 10
../tools/wait-for-rollout.sh deployment productpage-v1 bookinfo-v2 10

# expose bookinfo on https
kubectl apply -f argo/config/domain/wildcard/edge/2.2.a-tls-multiple-upstream.yaml

# setup keycloak user/groups 
cd ../keycloak/
./scripts/keycloak-setup-virtualservice.sh

# echo proxy url
echo 
echo "installation complete:"
echo
echo "run the commands below to access argocd dashboard at argocd.example.com domain:"
echo 
echo "cat <<EOF | sudo tee -a /etc/hosts"
echo "$(kubectl -n gloo-system get service gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}') argocd.example.com"
echo "EOF"
echo
echo "access argocd at http://argocd.example.com/argo"
echo "alternatively, access argocd using port-forward command: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo
echo "argocd credentials:"
echo "user: admin"
echo "password: solo.io"
echo 
echo "access the bookinfo application at: $(glooctl proxy url --port https | cut -d: -f1-2)/productpage"
echo
echo "additional gloo edge feature demos can be found here: cd bookinfo/argo/config/domain/wildcard/edge"
echo
echo "keycloak credentials for bookinfo demo:"
echo "user: user1"
echo "password: password"
echo 
