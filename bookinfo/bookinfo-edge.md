# bookinfo gloo-edge demo

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- Gloo Edge Enterprise - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-edge)
- Keycloak - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/keycloak)

## bookinfo app architecture
![bookinfo image](https://istio.io/latest/docs/examples/bookinfo/noistio.svg)

### deploy bookinfo-v1 application
Navigate to the bookinfo directory
```
cd bookinfo
```

Deploy the bookinfo-v1 app
```
kubectl apply -f argo/deploy/bookinfo-v1/default/bookinfo-v1-default.yaml
```

**NOTE:** This app will only have reviews-v2 which is black stars

watch status of bookinfo-v1 deployment
```
kubectl get pods -n bookinfo-v1 -w
```

### deploy bookinfo-beta application

Deploy the bookinfo-beta app
```
kubectl apply -f argo/deploy/bookinfo-beta/default/bookinfo-beta-default.yaml
```

**NOTE:** This app will have `reviews-v1` (no reviews), `reviews-v2` (black stars), and `reviews-v3` (red stars)

watch status of bookinfo-beta deployment
```
kubectl get pods -n bookinfo-beta -w
```

## deploy bookinfo virtualservices and validate
The examples below will take you through the many features that the `VirtualService` can provide to users of Gloo Edge

### single route virtualservice
Deploying the manifest below will expose our virtual service using gloo.
```
kubectl apply -f argo/virtualservice/edge/1-bookinfo-vs-single.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/1-bookinfo-vs-single/
```

#### view your exposed bookinfo-v1 service in the browser
Get your gateway URL
```
glooctl proxy url
```

In your browser navigate to http://$(glooctl proxy url)/productpage

We should expect to see the bookinfo application with just black stars

### traffic splitting
Applying the manifest below will split traffic 50/50 between `bookinfo-v1` and `bookinfo-beta` applications. 
```
kubectl apply -f argo/virtualservice/edge/2-bookinfo-multi-vs.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/2-bookinfo-multi-vs/
```

The added configuration below instructs gloo to split traffic across multiple destination upstreams with specified weights
```
routeAction:
        multi:
          destinations:
          - destination:
              upstream:
                name: bookinfo-v1-productpage-9080
                namespace: gloo-system
            weight: 5
          - destination:
              upstream:
                name: bookinfo-beta-productpage-9080
                namespace: gloo-system
            weight: 5
```

### tls
Applying the manifests below will build upon the last example and secure TLS with a `secretRef` to our upstream TLS secret.
```
kubectl apply -f argo/virtualservice/edge/3-bookinfo-tls-multi-vs.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/3-bookinfo-tls-multi-vs/
```

The added configuration below instructs gloo to reference a secret named `upstream-tls` in the `gloo-system` namespace for the tls certificate
```
 sslConfig:
    secretRef:
      name: upstream-tls
      namespace: gloo-system
```

#### view your exposed bookinfo service in the browser using https
Get your gateway URL
```
glooctl proxy url
```

In your browser navigate to https://$(glooctl proxy url)/productpage

### extauth
Applying the manifests below will build upon the last example and configure keycloak for extauth. Note that if you have not completed keycloak tutorial then [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/keycloak) before moving forward with this step
```
kubectl apply -f argo/virtualservice/edge/4-bookinfo-extauth-tls-multi-vs.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/4-bookinfo-extauth-tls-multi-vs/
```

The added configuration below instructs gloo to use keycloak by referencing a configmap named `keycloak-oauth` in the `gloo-system` namespace
```
options:
      extauth:
        configRef:
          name: keycloak-oauth
          namespace: gloo-system
```

### keycloak login
At this point, if you refresh your browser you should be redirected to the keycloak login page. Sign in with the following credentials
```
Username: User1
Password: password
```

### instance rate limit
Applying the manifests below will build upon the last example and add an instance rate limit for authenticated and anonymous users.
```
kubectl apply -f argo/virtualservice/edge/5a-bookinfo-irl-extauth-tls-multi-vs.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/5a-bookinfo-irl-extauth-tls-multi-vs/
```

The added configuration below rate limits anonymous and authorized users at different rates
```
ratelimitBasic:
        anonymousLimits:
          requestsPerUnit: 5
          unit: MINUTE
        authorizedLimits:
          requestsPerUnit: 20
          unit: MINUTE
```

### testing instance ratelimit
Navigate to your bookinfo application and refresh until you hit the instance ratelimit. This should result in a `HTTP ERROR 429` error code. Wait for the instance ratelimit to pass and you will be able to access the page again.

### global rate limit
Applying the manifests below will build upon the last example and switch out the instance rate limit for a global rate limit of 10 requests per minute.
```
kubectl apply -f argo/virtualservice/edge/5b-bookinfo-grl-extauth-tls-multi-vs.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/5b-bookinfo-grl-extauth-tls-multi-vs/
```

The added configuration below instructs gloo to refer to a global RateLimitConfig by referencing a configmap named `global-limit` in the `gloo-system` namespace
```
rateLimitConfigs:
        refs:
        - name: global-limit
          namespace: gloo-system
```

The associated `global-limit` configmap can also be seen as part of the configuration, which sets the global ratelimit to 10 requests per minute.
```
apiVersion: ratelimit.solo.io/v1alpha1
kind: RateLimitConfig
metadata:
  name: global-limit
  namespace: gloo-system
spec:
  raw:
    descriptors:
    - key: generic_key
      rateLimit:
        requestsPerUnit: 10
        unit: MINUTE
      value: count
    rateLimits:
    - actions:
      - genericKey:
          descriptorValue: count
```

### testing global ratelimit
Navigate to your bookinfo application and refresh until you hit the global ratelimit. This should result in a `HTTP ERROR 429` error code. Wait for the global ratelimit to pass and you will be able to access the page again.

### waf
Applying the manifests below will build upon the last example add a web application firewall example that will restrict logging into the bookinfo application so that logging in with any numbers (i.e. user123) will result in an error. 
```
kubectl apply -f argo/virtualservice/edge/6-bookinfo-waf-grl-extauth-tls-multi-vs.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/6-bookinfo-waf-grl-extauth-tls-multi-vs/
```

The added configuration below instructs gloo to use the `waf` feature
```
waf:
        customInterventionMessage: Username should only contain letters
        ruleSets:
        - ruleStr: |
            # Turn rule engine on
            SecRuleEngine On
            SecRule ARGS:/username/ "[^a-zA-Z]" "t:none,phase:2,deny,id:6,log,msg:'allow only letters in username'"
```

### transformation
Applying the manifests below will build upon the last example and add a transformation that will transform the 429 rate limit error code into a more descriptive and colorful webpage. 
```
kubectl apply -f argo/virtualservice/edge/7-bookinfo-trans-waf-grl-extauth-tls-multi-vs.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/virtualservice/edge/7-bookinfo-trans-waf-grl-extauth-tls-multi-vs/
```

The added configuration below instructs gloo to use the `transformations` feature
```
transformations:
        responseTransformation:
          transformationTemplate:
            body:
              text: '{% if header(":status") == "429" %}<html><body style="background-color:powderblue;"><h1>Too
                many Requests!</h1><p>Try again after 10 seconds</p></body></html>{%
                else %}{{ body() }}{% endif %}'
            parseBodyBehavior: DontParse
```

### testing transformations
Navigate to your bookinfo application and refresh until you hit the global ratelimit. This time the `HTTP ERROR 429` page that we were hitting before should now be translated into a more user-friendly view

## conclusion
At this point you have successfully navigated through exploring many features where Gloo Edge can bring value! There is a lot to digest so feel free to go back and re-test configurations to better familiarize yourself.

## cleanup
to remove bookinfo application
```
kubectl delete -f argo/virtualservice/edge/7-bookinfo-trans-waf-grl-extauth-tls-multi-vs.yaml
kubectl delete -f argo/deploy/bookinfo-v1/default/bookinfo-v1-default.yaml
kubectl delete -f argo/deploy/bookinfo-v1/default/bookinfo-beta-default.yaml
```

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)