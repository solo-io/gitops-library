#!/bin/bash

mgmt_context="mgmt"

kubectl apply -f ../mgmt/1.1.a.mgmt-root-trust.yaml --context ${mgmt_context}

kubectl apply -f ../mgmt/1.2.a.mgmt-workspace.yaml --context ${mgmt_context}

kubectl apply -f ../mgmt/1.2.b-global-workspace-settings.yaml --context ${mgmt_context}