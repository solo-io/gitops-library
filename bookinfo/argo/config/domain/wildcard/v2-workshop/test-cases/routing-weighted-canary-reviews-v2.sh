#!/bin/bash

cluster1_context="cluster1"

kubectl apply -f ../cluster1/1.3.a-workspace-settings.yaml --context ${cluster1_context}

kubectl apply -f ../cluster1/2.1.d-routing-weighted-canary-reviews-v2.yaml --context ${cluster1_context}