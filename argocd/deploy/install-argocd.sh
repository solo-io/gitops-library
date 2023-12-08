#!/bin/bash

INSTALL_TYPE=$1 # default/insecure/insecure-rootpath
CONTEXT=$2

# argo install type
if [[ ${INSTALL_TYPE} == "" ]]
  then
    INSTALL_TYPE="default"
fi
  
echo "Beginning install on context ${CONTEXT}...."

# create argocd namespace
kubectl --context ${CONTEXT} create namespace argocd

# deploy argocd
until kubectl --context ${CONTEXT} apply -k ${INSTALL_TYPE}/; do sleep 2; done

# bcrypt(password)=$2a$10$79yaoOg9dL5MO8pn8hGqtO4xQDejSEVNWAGQR268JHLdrCw6UCYmy
# password: solo.io
kubectl --context ${CONTEXT} -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$79yaoOg9dL5MO8pn8hGqtO4xQDejSEVNWAGQR268JHLdrCw6UCYmy",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

# create argo app-of-apps project
kubectl apply --context ${CONTEXT} -f- <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  destinations:
  - namespace: '*'
    server: '*'
  sourceRepos:
  - '*'
EOF