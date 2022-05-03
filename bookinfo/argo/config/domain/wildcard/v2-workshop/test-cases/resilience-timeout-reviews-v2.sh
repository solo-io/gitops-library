#!/bin/bash

cluster1_context="cluster1"

kubectl apply -f ../cluster1/2.2.a-workspace-settings-federation.yaml --context ${cluster1_context}

kubectl apply -f ../cluster1/2.3.b-routing-federation-failover.yaml --context ${cluster1_context}

kubectl apply -f ../cluster1/3.1.a.resilience-fault-ratings.yaml --context ${cluster1_context}

kubectl apply -f ../cluster1/3.2.a.resilience-timeout-reviews-v2.yaml --context ${cluster1_context}
