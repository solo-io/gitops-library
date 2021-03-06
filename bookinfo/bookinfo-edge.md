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
kubectl apply -f argo/app/namespace/bookinfo-v1/non-mesh/1.2.a-reviews-v1-v2.yaml
```

**NOTE:** This app will have `reviews-v1` (no stars) and `reviews-v2` (black stars)

watch status of bookinfo-v1 deployment
```
kubectl get pods -n bookinfo-v1 -w
```

### deploy bookinfo-v2 application

Deploy the bookinfo-v2 app
```
kubectl apply -f argo/app/namespace/bookinfo-v2/non-mesh/1.3.a-reviews-all.yaml
```

**NOTE:** This app will have `reviews-v1` (no reviews), `reviews-v2` (black stars), and `reviews-v3` (red stars)

watch status of bookinfo-v2 deployment
```
kubectl get pods -n bookinfo-v2 -w
```

## deploy bookinfo virtualservices and validate
The examples below will take you through the many features that the `VirtualService` can provide to users of Gloo Edge

### single route virtualservice
Deploying the manifest below will expose our virtual service using gloo.
```
kubectl apply -f argo/config/domain/wildcard/edge/1.1.a-route-single-upstream.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/1.1.a-route-single-upstream
```

#### view your exposed bookinfo-v1 service in the browser
Get your gateway URL
```
glooctl proxy url
```

In your browser navigate to http://$(glooctl proxy url)/productpage

We should expect to see the bookinfo application with just black stars

### traffic splitting
Applying the manifest below will split traffic 50/50 between `bookinfo-v1` and `bookinfo-v2` applications. 
```
kubectl apply -f argo/config/domain/wildcard/edge/1.2.a-route-multiple-upstream.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/1.2.a-route-multiple-upstream
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
                name: bookinfo-v2-productpage-9080
                namespace: gloo-system
            weight: 5
```

### tls
Applying the manifests below will build upon the last example and secure TLS with a `secretRef` to our upstream TLS secret.
```
kubectl apply -f argo/config/domain/wildcard/edge/2.2.b-tls-multiple-upstream.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/2.2.b-tls-multiple-upstream
```

The added configuration below instructs gloo to reference a secret named `upstream-tls` in the `gloo-system` namespace for the tls certificate
```
 sslConfig:
    secretRef:
      name: upstream-tls
      namespace: gloo-system
```

In this step we have also exposed our keycloak on port 80 with a VirtualService for our next lab configuring oAuth
```
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: keycloak-vs
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matchers:
      - prefix: /keycloak/
      options:
        prefixRewrite: /auth/
      routeAction:
        single:
          upstream:
            name: default-keycloak-8080
            namespace: gloo-system
    - matchers:
      - prefix: /
      routeAction:
        single:
          upstream:
            name: default-keycloak-8080
            namespace: gloo-system
```

#### view your exposed bookinfo service in the browser using https
Get your gateway URL
```
glooctl proxy url
```

In your browser navigate to https://$(glooctl proxy url)/productpage

### extauth
Applying the manifests below will build upon the last example and configure keycloak for extauth. Note that if you have not completed keycloak tutorial then [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/keycloak) before moving forward with the next steps

### setting up keycloak
In a previous step we have deployed keycloak on our cluster, however at this point we have not exposed keycloak or set anything up.

Now that we have keycloak exposed by gloo edge, we need to set it up with some users and set some attributes within keycloak

Run the script below to set up keycloak with two users `user1/password` and `user2/password`
```
../keycloak/scripts/keycloak-setup-virtualservice.sh
```

### deploy virtualservice with extauth config
```
kubectl apply -f argo/config/domain/wildcard/edge/2.3.a-tls-extauth-keycloak.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/2.3.a-tls-extauth-keycloak/
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

### VirtualHost rate limit
Applying the manifests below will build upon the last example and add a rate limit at the VirtualHost level for authenticated and anonymous users.
```
kubectl apply -f argo/config/domain/wildcard/edge/2.4.a-vhost-ratelimit.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/2.4.a-vhost-ratelimit
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

### testing VirtualHost ratelimit
Navigate to your bookinfo application and refresh until you hit the ratelimit. This should result in a `HTTP ERROR 429` error code. Wait for the instance ratelimit to pass and you will be able to access the page again.

### global rate limit
Applying the manifests below will build upon the last example and switch out the instance rate limit for a global rate limit of 10 requests per minute.
```
kubectl apply -f argo/config/domain/wildcard/edge/2.4.b-global-ratelimit.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/2.4.b-global-ratelimit
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
kubectl apply -f argo/config/domain/wildcard/edge/2.5.a-simple-waf.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/2.5.a-simple-waf
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
kubectl apply -f argo/config/domain/wildcard/edge/2.6.a-transformation.yaml
```

### view kustomize configuration
If you are curious to review the entire VirtualService configuration in more detail, run the kustomize command below
```
kubectl kustomize overlay/config/domain/wildcard/edge/2.6.a-transformation
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
kubectl delete -f argo/config/domain/wildcard/edge/2.6.a-transformation.yaml
kubectl delete -f argo/app/namespace/bookinfo-v1/non-mesh/1.2.a-reviews-v1-v2.yaml
kubectl delete -f argo/app/namespace/bookinfo-v2/non-mesh/1.3.a-reviews-all.yaml
```

remove keycloak
```
kubectl delete -f ../keycloak/argo/default/keycloak-default-12-0-4.yaml
```

removing gloo-edge depends on which overlay path was installed when going through the installation lab. Please uninstall the argo application you originally installed
```
kubectl delete -f ../gloo-edge/argo/ee/<path/to/version/used>
```

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)