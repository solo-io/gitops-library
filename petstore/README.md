## deploy petstore gloo-portal demo app

## Prerequisites
- Kubernetes clusters up and authenticated to kubectl
- argocd - [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/argocd)
- gloo-edge[Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-edge)
- gloo-portal [Follow this Tutorial Here](https://github.com/solo-io/gitops-library/tree/main/gloo-portal)

If you have been following along with all of the tutorials above, publishing your petstore API is really simple. This guide will take you through the process

# deploy upstream-tls secret
The petstore portal uses an `sslConfig.secretRef` named `upstream-tls` in the `gloo-system` namespace to terminate TLS connections. Lets create this cert as a Kubernetes Secret to be used in our Virtual Service. If you have your own key/cert pair, you can use those instead of creating self-signed certs using the instructions below, just name the secret `upstream-tls` to work with the petstore demo
```
kubectl apply -f - <<EOF
apiVersion: v1
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMrVENDQWVHZ0F3SUJBZ0lVREtCekt3Vkt5WFgybUk2R3NJMjl4REFIWFE0d0RRWUpLb1pJaHZjTkFRRUwKQlFBd0RERUtNQWdHQTFVRUF3d0JLakFlRncweU1UQTNNall4TlRVd01UbGFGdzB5TWpBM01qWXhOVFV3TVRsYQpNQXd4Q2pBSUJnTlZCQU1NQVNvd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFS0FvSUJBUUN6CnhvZCtodmtneldMS1V2TlFZWnVINjVuRmliQjJINm5BTG51bUJZMENibDBaZU4ydW9rRFVVTXk1TC9lS2llazYKTDRqSHJKU3RiTjBUemhmTEovRG1KdW9RQUNSS3FHZzlCdlg4R2wyTHF2SDB3dk93d1hCVCsrSVhhWUxYbXB4NgpWM2t6Z2ZoMW5taUVDU1d5NFd5OVRvajBDY0JJUkdHNDlubTBlcEFBdnJCa0JEdnFZZHAyN0lhdjBBbXBHZjlkCmphbnZKWGZEMTNhS0YvbkZZUXdsUm96MlBwdkNIY296M0pBM2pWczIzaW4rb09jV21LRVJwMXZwTU1TRXR1UTMKQ3lKdzZWS01JU2srZ2RLSDlHWllaQlFtZlY4U0FCcTZRUVFNbmp2dzZVSnVUa2M5RzJpUm5rcXRvQmxYY241RwpuNUhiYkpIWmNVY09sbTNPMXpKM0FnTUJBQUdqVXpCUk1CMEdBMVVkRGdRV0JCUllSa0FnaVVPK2hQOWFubzJTCm43RkFJMTFGT2pBZkJnTlZIU01FR0RBV2dCUllSa0FnaVVPK2hQOWFubzJTbjdGQUkxMUZPakFQQmdOVkhSTUIKQWY4RUJUQURBUUgvTUEwR0NTcUdTSWIzRFFFQkN3VUFBNElCQVFDdXp6Tm1PdUtETkJvbXQwV1hJWXhnSGNXKwppamNMUlZDUElabXdlRmwyZnF2cWdKYzNYKzNGQlRJZWVnd0pkQjhxU0NMSG5QY2IwdUJ4VVFUSDJWbld1blFvCjcyN0prN25TRnRjMUJya2tOSjF5K1lXQnJUVVBranJhR1JaVGMxaFdJUDN6SS9zNlhRWEpNQVJMTS85Z3dDU1kKSTBmVk14SWIySlFkQmlNVURucUt3Q0psY25ISnhaeHpUUmcyZnlUV3dubHpDRFRXQmNkMDBsVkh3NTNody9JZAowV1d1NTRPNWkvM3hPSkRMUFFscDMzMzg0UDE5ODZZZExSaFNiVlBJRk14c051SGpKN3l1WGY4OThqVy9WRHl0Cis0MVlzU2hNbC9xeENFdk01b1VFaDlwaG5uZGlWVUFaSjZvdGVzclpGU3NKRTVtSEl5N25xNlFBQW5TSAotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  tls.key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRQ3p4b2QraHZrZ3pXTEsKVXZOUVladUg2NW5GaWJCMkg2bkFMbnVtQlkwQ2JsMFplTjJ1b2tEVVVNeTVML2VLaWVrNkw0akhySlN0Yk4wVAp6aGZMSi9EbUp1b1FBQ1JLcUdnOUJ2WDhHbDJMcXZIMHd2T3d3WEJUKytJWGFZTFhtcHg2VjNremdmaDFubWlFCkNTV3k0V3k5VG9qMENjQklSR0c0OW5tMGVwQUF2ckJrQkR2cVlkcDI3SWF2MEFtcEdmOWRqYW52SlhmRDEzYUsKRi9uRllRd2xSb3oyUHB2Q0hjb3ozSkEzalZzMjNpbitvT2NXbUtFUnAxdnBNTVNFdHVRM0N5Snc2VktNSVNrKwpnZEtIOUdaWVpCUW1mVjhTQUJxNlFRUU1uanZ3NlVKdVRrYzlHMmlSbmtxdG9CbFhjbjVHbjVIYmJKSFpjVWNPCmxtM08xekozQWdNQkFBRUNnZ0VCQUxDRGthNHVJSmFRa3h0TTd4SlJoRUNrbDh0Wk1pWUpXTWNWM05wYVFPWE8KTHlNL2hZcGVUWUVxQkprZis5SFBMMnl1RjRMV2RQVURHdDdEVUtGc2loK3d2Y2tRR3BJallKWHJLOE5vcjhqZgpBOHJyVUJLUkhCV2FENWdsUlE4bEE5Y3I1QmtxMkNYRWI2S1V5S3NtbzNvTWpuUHV6eGtsNnoyTTVGck1yRy9OCkplTDVza1lzdjZjbUFLbHMyd1JzVjZlTTJFOVJVVGVJZjJ0QnVFaDdZL1NpR0h3Z1lOTzF1RFBwSXpnZG5wQkgKUWQ2d2hNS0hUNFdvdnJqcGhtRXRzMGxEY0ZaN3lJaUZFOW1OTVlzMEc1bDBJNHFjZHBPM3lpTncxK2g0MUt5NgpaR2JaS2ZoMU5jNWVqeDhnTEc1RS9UMUZYL2EzRVlhY1EzWnhxZmEyemFFQ2dZRUE0VkJmSDZPUWtiditGOUdJCnp6VFY2MzJkSmNyR0hmbmtZVnRpYmNkZ2d2ZnFmcWZvTTY0MG1KOFZaaUFwczk2VHZWa1YvTWFDaExpZitRa3kKQkJoRlRYNnh1WGlndGVCdEExOC94WWRYc3ZNLzA4TnRVSndoVDFubnVVQXRDckd3L2JvdUZFZWtYQkwvL2p1awp1cDd3KzR4a3F5djAycjFId3o1bFcram43QTBDZ1lFQXpFSnl1VE1yRTVoMHlwQmdNZDhveFJKWjlacS9EVjUyCmtHS3hwbDR6U0R2MXduZ3Z2N3FVRnJxSkNxeFdCV2JnU2ZhazQyVHV4OGVjU1h5RTM0b2pUdngrN1hsREI4QlMKTndoRFM2OFl4Rll6TEtTd21rNnFmdEhaQkN0YzhpVFN0RUNLUGtBKzVhYklVZlhrTjdrV3pBQUFFR2tCc3pSYwpCQmpNNUp0Z2c1TUNnWUJ2M2pMTWg2NXczVEVFYkhHTHg0VHEzanhYRmoyVmhvd2cxbm1oWGR1S1MwTXZUWGlaCnFFWE8vVFZudGxKZVR3VjFmclRQQTFTc1J1cU9nRVZJQ1REbmtCNzNvbS9RdmJRQ2Q1azNIc0twUStNTjVqcngKU2dPejNVU1RFczBLUVQxS1ROVXlGbndCaHlGNC9lNEZCb05Kc2VRTnBNNTJpSUlINjRQeHhVclpSUUtCZ0Vzdwp4c1NRSm5KUE0rY0JZTGZiRzBuNGFHODE2TkNHRG9VMkg0bExzZnNNUDNxMy9YUEp2Z3ZqM09DMThmQ0pIMVY2CjJ0WHVhTXZZR2hzZklGYWRwa1BFUlFFc0cxVzJJVTJxMkFMN1VOV3RtYWI4ZFJwSWpSQ2tOUXdJM20wd3l2T1oKc29vWjRrMXRxTjRxOHpqa0JKVlNCclFEdzZGeFM5SWlRd0tBZy9YTEFvR0FlTjdkRDQvNzllSUpDb0VDdEJZTgpLTjJoNEx5VWJpZzhzUnFxRlRmdWFLNnlBOXpaWUpwcjBPQXFyWDdRU2w2RFRLcjFzKzZ6Ny9YRzE3ZWp1VEw1CitUZHdjYWd1RDY0VVg4cSt1MFZwTjFPNU45QjNTa1ZXazYvTXdLZVhmU0tuTHBoam5nLzJHUUR0NGRwdWdOUTcKcXZQejFzYlpsN1oweFFSK0pGc0xVZnc9Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K
kind: Secret
metadata:
  name: upstream-tls
  namespace: gloo-system
type: kubernetes.io/tls
EOF
```

# deploy the petstore portal demo
Navigate to the petstore directory
```
cd petstore
```

Good thing is, everything is already packaged up in the form of a single argocd application!
```
kubectl apply -f argo/demo/domain/default/petstore-portal-demo.yaml
```

### view kustomize configuration
If you are curious to review the entire API product configuration in more detail, run the kustomize command below
```
kubectl kustomize demo/domain/default/
```

As you can see there are many configuration components that make up a proper API product. Gloo Portal aims to simplify managing all of this configuration into a set of `CustomResource` objects such as `APIDoc`, `APIProduct`, `Environment`, and `Portal` to name a few. A good place to start to familiarize yourself is the [Gloo Portal Concepts](https://docs.solo.io/gloo-portal/latest/concepts/) documentation.

## View your custom resources
See Portals:
```
$ kubectl get portals
NAME               AGE
ecommerce-portal   2m5s
```

See APIDoc:
```
$ kubectl get apidoc
NAME                        AGE
petstore-openapi-v1-pets    3m3s
petstore-openapi-v1-users   3m3s
petstore-openapi-v2-full    3m3s
```

See APIProduct:
```
$ kubectl get apiproduct
NAME               AGE
petstore-product   3m21s
```

See Environment:
```
$ kubectl get environment
NAME   AGE
dev    3m44s
```

See Petstore deployment
```
$ kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
petstore-v1-76cc557d6-dp5qr    1/1     Running   0          4m37s
petstore-v2-56796cb9cf-jj6sp   1/1     Running   0          4m37s
```

## Navigating to your Portal

### access admin UI of Gloo Portal with port-forwarding
```
kubectl port-forward -n gloo-portal svc/gloo-portal-admin-server 8000:8080
```

access gloo-portal dashboard at `http://localhost:8000`

You should see that one Portal has been created. Feel free to click around on the Gloo Portal UI

### poor mans DNS: update /etc/hosts file to be able to access our Portal (Edge)
```
cat <<EOF | sudo tee -a /etc/hosts
$(kubectl -n gloo-system get service gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}') portal.example.com
$(kubectl -n gloo-system get service gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}') api.example.com
EOF
```

### poor mans DNS: update /etc/hosts file to be able to access our Portal (Istio)
```
cat <<EOF | sudo tee -a /etc/hosts
$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}') api.example.com
$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}') petstore.example.com
EOF
```

## Accessing your Petstore Portal
Under the Portals tab, click and open the `portal.example.com` link to access your Portal. You can also click on the tile to drill into more detail about your portal in the browser.

# login to petstore portal htpasswd auth user
```
username: developer1
password: gloo-portal1
```

## cleanup
to remove petstore gloo-portal demo application
```
kubectl delete -f argo/demo/domain/default/petstore-portal-demo.yaml
```

## Back to Table of Contents
[Back to Table of Contents](https://github.com/solo-io/gitops-library#table-of-contents---labs)