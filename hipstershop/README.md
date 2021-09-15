# hipstershop gloo-edge demo

## deploy hipstershop application
Navigate to the hipstershop directory
```
cd hipstershop
```

Deploy the hipstershop-default app. This will deploy the base hipstershop application in the default namespace.
```
kubectl apply -f argo/deploy/hipstershop-default.yaml
```

watch status of hipstershop deployment
```
kubectl get pods -n default -w
```

## deploy hipstershop virtualservice and validate
```
k apply -f argo/virtualservice/edge/1-hipstershop-vs-single.yaml
```

check glooctl
```
glooctl get vs
```

output should look similar to below:
```
$ glooctl get vs
+-----------------+--------------+---------+------+----------+-----------------+---------------------------------+
| VIRTUAL SERVICE | DISPLAY NAME | DOMAINS | SSL  |  STATUS  | LISTENERPLUGINS |             ROUTES              |
+-----------------+--------------+---------+------+----------+-----------------+---------------------------------+
| hipstershop-vs  |              | *       | none | Accepted |                 | / ->                            |
|                 |              |         |      |          |                 | gloo-system.default-frontend-80 |
|                 |              |         |      |          |                 | (upstream)                      |
+-----------------+--------------+---------+------+----------+-----------------+---------------------------------+
```

Run a `glooctl check`
```
$ glooctl check
Checking deployments... OK
Checking pods... OK
Checking upstreams... OK
Checking upstream groups... OK
Checking auth configs... OK
Checking rate limit configs... OK
Checking VirtualHostOptions... OK
Checking RouteOptions... OK
Checking secrets... OK
Checking virtual services... OK
Checking gateways... OK
Checking proxies... OK
Checking rate limit server... OK
No problems detected.

Detected Gloo Federation!
Checking Gloo Instance cluster1-gloo-system... 
Checking deployments... OK
Checking pods... OK
Checking settings... OK
Checking upstreams... OK
Checking upstream groups... OK
Checking auth configs... OK
Checking virtual services... OK
Checking route tables... OK
Checking gateways... OK
Checking proxies... OK
```

## navigate to hipstershop application
get the envoy proxy url
```
glooctl proxy url
```

output should look similar to below:
```
$ glooctl proxy url
http://172.18.3.1:80
```

You should now be able to explore the hipstershop application!

## cleanup
to remove hipstershop application
```
kubectl delete -f argo/virtualservice/edge/1-hipstershop-vs-single.yaml
kubectl delete -f argo/deploy/hipstershop-default.yaml
```

## Next Steps - Deploy bookinfo application and expose through gloo-edge
[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/bookinfo)
