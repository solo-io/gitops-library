## deploy petstore gloo-portal demo app

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- gloo-edge[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-edge)
- gloo-portal [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-portal)
- keycloak [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/keycloak)

If you have been following along with all of the tutorials above, publishing your petstore API is really simple. This guide will take you through the process

### view kustomize configuration
If you are curious to review the entire API product configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/swaggerapi/gloo-portal-1-0-2/
```

As you can see there are many configuration components that make up a proper API product. Gloo Portal aims to simplify managing all of this configuration into a set of `CustomResource` objects such as `APIDoc`, `APIProduct`, `Environment`, and `Portal` to name a few. A good place to start to familiarize yourself is the [Gloo Portal Concepts](https://docs.solo.io/gloo-portal/latest/concepts/) documentation.
```
$ cat overlay/swaggerapi/gloo-portal-1-0-2/kustomization.yaml 
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- petstore-v1.yaml
- petstore-v2.yaml
- petstore-openapi-v1-pets-apidoc.yaml 
- petstore-openapi-v1-users-apidoc.yaml
- petstore-openapi-v2-full-apidoc.yaml
- petstore-apiproduct.yaml    
- dev-environment-wplan.yaml
- petstore-portal-wstatic.yaml
- default-petstore-portal-faq-cm.yaml
- developer-group-wplan.yaml
- developer1-user.yaml
```

## Publish your petstore API
Good thing is, everything is already packaged up in the form of a single argocd application!
```
kubectl apply -f argo/petstore-apiproduct-1-0-2.yaml
```

## View your custom resources
See Portals:
```
$ k get portals
NAME               AGE
ecommerce-portal   2m5s
```

See APIDoc:
```
$ k get apidoc
NAME                        AGE
petstore-openapi-v1-pets    3m3s
petstore-openapi-v1-users   3m3s
petstore-openapi-v2-full    3m3s
```

See APIProduct:
```
$ k get apiproduct
NAME               AGE
petstore-product   3m21s
```

See Environment:
```
$ k get environment
NAME   AGE
dev    3m44s
```

See Petstore deployment
```
$ k get pods
NAME                           READY   STATUS    RESTARTS   AGE
petstore-v1-76cc557d6-dp5qr    1/1     Running   0          4m37s
petstore-v2-56796cb9cf-jj6sp   1/1     Running   0          4m37s
```

## Navigating to your Portal

### access admin UI of Gloo Portal with port-forwarding
access gloo-portal dashboard at `http://localhost:8000`
```
kubectl port-forward -n gloo-portal svc/gloo-portal-admin-server 8000:8080
```

You should see that one Portal has been created. Feel free to click around on the Gloo Portal UI

### poor mans DNS: update /etc/hosts file to be able to access our Portal
```
cat <<EOF | sudo tee -a /etc/hosts
$(kubectl -n gloo-system get service gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}') portal.mycompany.corp
$(kubectl -n gloo-system get service gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}') api.mycompany.corp
EOF
```

## Accessing your Petstore Portal
Under the Portals tab, click and open the `portal.mycompany.mycorp` link to access your Portal. You can also click on the tile to drill into more detail about your portal in the browser.

# login to petstore portal htpasswd auth user
```
username: developer1
password: gloo-portal1
```

## cleanup
to remove petstore gloo-portal demo application
```
kubectl delete -f argo/petstore-apiproduct-1-0-2.yaml
```

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)