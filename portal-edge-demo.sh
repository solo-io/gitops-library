#!/bin/bash

license_key=$1
ingress_type="edge"
portal_version="1-2-0-beta4"
edge_version="1-9-1"

# check if cluster exists, uses current context if it does
CONTEXT=`kubectl config current-context`
if [[ ${CONTEXT} == "" ]]
  then
    echo "You do not have a curent kubernetes cluster.  Please create one."
    exit 1
  fi

# check to see if license key variable was passed through, if not prompt for key
if [[ ${license_key} == "" ]]
  then
    # provide license key
    echo "Please provide your Gloo Edge Enterprise License Key:"
    read license_key
fi

# check OS type
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        BASE64_LICENSE_KEY=$(echo -n "${license_key}" | base64 -w 0)
elif [[ "$OSTYPE" == "darwin"* ]]; then
        # Mac OSX
        BASE64_LICENSE_KEY=$(echo -n "${license_key}" | base64)
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
./install-argocd.sh

# wait for argo cluster rollout
../tools/wait-for-rollout.sh deployment argocd-server argocd 10

# install gloo-edge without gloo-fed
cd ../gloo-edge/
kubectl apply -f argo/ee/${edge_version}/gloo-edge-ee-helm-nofed-${edge_version}.yaml

# wait for gloo-edge rollout
../tools/wait-for-rollout.sh deployment gateway gloo-system 10

# install keycloak
#cd ../keycloak
#kubectl apply -f argo/default/keycloak-default-12-0-4.yaml
#../tools/wait-for-rollout.sh deployment keycloak default 10
#./scripts/keycloak-setup.sh

# install gloo-portal
cd ../gloo-portal/
# sed command to replace license key  
sed -i -e "s/<INSERT_LICENSE_KEY_HERE>/${license_key}/g" argo/${ingress_type}/gloo-portal-helm-${portal_version}.yaml
kubectl apply -f argo/${ingress_type}/gloo-portal-helm-${portal_version}.yaml
../tools/wait-for-rollout.sh deployment gloo-portal-admin-server gloo-portal 10

# install petstore api product
cd ../petstore/
kubectl apply -f argo/petstore-apiproduct-1-0-2-${ingress_type}.yaml

# echo port-forward commands
echo
echo "access gloo portal dashboard at http://localhost:8000"
echo "kubectl port-forward -n gloo-portal svc/gloo-portal-admin-server 8000:8080"
echo 
echo "access argocd dashboard:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443 --context <desired_context>"
echo
echo "Continue on with petstore portal lab in gitops-library git repo:"
echo "https://github.com/solo-io/gitops-library/tree/main/petstore"
echo 