# gitops-library
This Repo is meant to store useful application and config example references for deploying Solo products, example applications, and related config

## Table of Contents
- argo-rollouts
- argocd
- bombardier-loadgen
- bookinfo
- cert-manager
- gloo-edge
- gloo-mesh
- gloo-portal
- helloworld
- homer-portal
- httpbin
- istio
- keycloak
- petstore
- solowallet

## Repo Structure
Each application example is broken down into two directories: `deploy` for the application deployments and `config-examples` which provide examples for edge, mesh, or portal configuration examples for the respective app. Where possible, deployment options using ArgoCD as well as the direct YAML manifests are provided