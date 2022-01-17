# Prerequisites
- Kubernetes clusters up and authenticated to kubectl

## kubectl contexts
If you are using single cluster installation, then the script will use the default context so you can ignore this section.

Since we will potentially be using multiple clusters/contexts, it is useful to rename your contexts for a better experience
```
kubectl config get-contexts
kubectl config rename-contexts <current_name> <new_name>
export CONTEXT=<new_name>
```

## Navigate to the argocd directory
```
cd argocd
```

## install argocd
If you have done the above, just simply run the script to install argocd and optionally set the context.
```
./install-argocd.sh
```

Run this script to watch argocd install progress
```
../tools/wait-for-rollout.sh deployment argocd-server argocd 10
```

Output should look similar to below:
```
% ./tools/wait-for-rollout.sh deployment argocd-server argocd 10
No context specified. Using current context of mgmt
Waiting 10 seconds for deployment argocd-server to come up.
Waiting for deployment "argocd-server" rollout to finish: 0 of 1 updated replicas are available...
deployment "argocd-server" successfully rolled out
```

### input options
You can provide the inputs below to specify a configuration of argocd
```
./install-argocd.sh {SECURITY} {CONTEXT}
```

SECURITY options: `default`/`insecure`
- If undefined, the install will use the default install of argocd
- `insecure` option allows us to terminate TLS at the edge, and expose argocd using a VirtualService instead of port-forward commands

### access argoCD UI
using port forward, access argocd at localhost:8080 if using the `default` or `insecure` overlay; localhost:8080/argo if using the `insecure-rootpath` overlay
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Username: admin
Password: solo.io

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)