#!/bin/bash

cluster1_context="cluster1"

kubectl apply -f ../cluster1/2.2.a-workspace-settings-federation.yaml --context ${cluster1_context}

kubectl apply -f ../cluster1/2.3.b-routing-federation-failover.yaml --context ${cluster1_context}