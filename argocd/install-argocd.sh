#!/bin/bash

INSTALL_TYPE=$1 # default/insecure/insecure-rootpath
CONTEXT=$2

### If the CONTEXT is not specified, simply use the default context.
if [[ ${CONTEXT} == "" ]]
then
  CONTEXT=`kubectl config current-context`
  if [[ ${CONTEXT} == "" ]]
  then
    echo "You do not have a curent kubernetes cluster.  Please create one."
    exit 1
  fi
  echo "No context specified. Using default context of ${CONTEXT}"
fi

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