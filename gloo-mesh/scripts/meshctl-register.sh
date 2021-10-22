#!/bin/bash

# set management and remote contexts from script inputs
MGMT_CONTEXT=$1
REMOTE_CONTEXT=$2
export GLOO_MESH_VERSION=$3

### check to make sure that arguments were set before taking off
if [[ ${MGMT_CONTEXT} == "" ]] || [[ ${REMOTE_CONTEXT} == "" ]]
  then
  echo "Missing arguments. Proper usage is ./meshctl-register.sh <mgmt_context> <remote_context>"
  echo "example:"
  echo "./meshctl-register.sh mgmt cluster1"
  echo "would register cluster1 to gloo-mesh running on the mgmt context"
  exit 1
  else
  echo "Beginning gloo-mesh cluster registration...."
fi

# install meshctl 
curl -sL https://run.solo.io/meshctl/install | sh -
export PATH=$HOME/.gloo-mesh/bin:$PATH

# set SVC variable to enterprise-networking pod loadBalancer ip
SVC=$(kubectl --context ${MGMT_CONTEXT} -n gloo-mesh get svc enterprise-networking -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# register cluster with meshctl
meshctl cluster register --mgmt-context=${MGMT_CONTEXT} --remote-context=${REMOTE_CONTEXT} --relay-server-address=$SVC:9900 enterprise ${REMOTE_CONTEXT} --cluster-domain cluster.local
