#!/bin/bash

cluster1_context="cluster1"

kubectl apply -f ../cluster1/1.3.a-workspace-settings.yaml --context ${cluster1_context}

kubectl apply -f ../cluster1/2.1.c-routing-weighted-canary-reviews-v1.yaml --context ${cluster1_context}