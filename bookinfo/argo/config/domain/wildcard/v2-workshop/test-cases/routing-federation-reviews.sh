#!/bin/bash

cluster1_context="cluster1"

kubectl apply -f ../cluster1/2.2.a-workspace-settings-federation.yaml --context ${cluster1_context}

kubectl apply -f ../cluster1/2.2.b-routing-federation-reviews.yaml --context ${cluster1_context}