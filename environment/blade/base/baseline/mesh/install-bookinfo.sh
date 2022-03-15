#!/bin/bash

kubectl --context ${CLUSTER1} create ns bookinfo-frontends
kubectl --context ${CLUSTER1} create ns bookinfo-backends
bookinfo_yaml=https://raw.githubusercontent.com/istio/istio/1.11.7/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl --context ${CLUSTER1} label namespace bookinfo-frontends istio.io/rev=1-11
kubectl --context ${CLUSTER1} label namespace bookinfo-backends istio.io/rev=1-11
# deploy the frontend bookinfo service in the bookinfo-frontends namespace
kubectl --context ${CLUSTER1} -n bookinfo-frontends apply -f ${bookinfo_yaml} -l 'account in (productpage)'
kubectl --context ${CLUSTER1} -n bookinfo-frontends apply -f ${bookinfo_yaml} -l 'app in (productpage)'
# deploy the backend bookinfo services in the bookinfo-backends namespace for all versions less than v3
kubectl --context ${CLUSTER1} -n bookinfo-backends apply -f ${bookinfo_yaml} -l 'account in (reviews,ratings,details)'
kubectl --context ${CLUSTER1} -n bookinfo-backends apply -f ${bookinfo_yaml} -l 'app in (reviews,ratings,details),version notin (v3)'
# Update the productpage deployment to set the environment variables to define where the backend services are running
kubectl --context ${CLUSTER1} -n bookinfo-frontends set env deploy/productpage-v1 DETAILS_HOSTNAME=details.bookinfo-backends.svc.cluster.local
kubectl --context ${CLUSTER1} -n bookinfo-frontends set env deploy/productpage-v1 REVIEWS_HOSTNAME=reviews.bookinfo-backends.svc.cluster.local

kubectl --context ${CLUSTER2} create ns bookinfo-frontends
kubectl --context ${CLUSTER2} create ns bookinfo-backends
bookinfo_yaml=https://raw.githubusercontent.com/istio/istio/1.11.7/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl --context ${CLUSTER2} label namespace bookinfo-frontends istio.io/rev=1-11
kubectl --context ${CLUSTER2} label namespace bookinfo-backends istio.io/rev=1-11
# deploy the frontend bookinfo service in the bookinfo-frontends namespace
kubectl --context ${CLUSTER2} -n bookinfo-frontends apply -f ${bookinfo_yaml} -l 'account in (productpage)'
kubectl --context ${CLUSTER2} -n bookinfo-frontends apply -f ${bookinfo_yaml} -l 'app in (productpage)'
# deploy the backend bookinfo services in the bookinfo-backends namespace for all versions
kubectl --context ${CLUSTER2} -n bookinfo-backends apply -f ${bookinfo_yaml} -l 'account in (reviews,ratings,details)'
kubectl --context ${CLUSTER2} -n bookinfo-backends apply -f ${bookinfo_yaml} -l 'app in (reviews,ratings,details)'
# Update the productpage deployment to set the environment variables to define where the backend services are running
kubectl --context ${CLUSTER2} -n bookinfo-frontends set env deploy/productpage-v1 DETAILS_HOSTNAME=details.bookinfo-backends.svc.cluster.local
kubectl --context ${CLUSTER2} -n bookinfo-frontends set env deploy/productpage-v1 REVIEWS_HOSTNAME=reviews.bookinfo-backends.svc.cluster.local