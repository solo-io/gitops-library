#!/bin/bash

seconds=0
OUTPUT=0
# example rollout would be deployments/<deployment_name>
rollout_type=$1
rollout_name=$2
namespace=$3
period=$4

while [ "$OUTPUT" -ne 1 ]; do
  OUTPUT=`kubectl get ${rollout_type}/${rollout_name} -n ${namespace} 2>/dev/null | grep -c ${rollout_name}`;
  seconds=$((seconds+${period}))
  printf "Waiting %s seconds for ${rollout_type} ${rollout_name} to come up.\n" "${seconds}"
  sleep ${period}
  kubectl rollout status ${rollout_type}/${rollout_name} -n ${namespace}
done