# Installing with Helm

## Flagger with default prometheus
```
helm repo add flagger https://flagger.app

helm upgrade -i flagger flagger/flagger \
--namespace gloo-system \
--set prometheus.install=true \
--set meshProvider=gloo
```

## Flagger using Gloo Edge Enterprise prometheus
```
helm repo add flagger https://flagger.app

helm upgrade -i flagger flagger/flagger \
--namespace gloo-system \
--set prometheus.install=false \
--set metricsServer="http://glooe-prometheus-server.gloo-system:80" \
--set meshProvider=gloo
```

### Uninstall
```
helm uninstall flagger -n gloo-system
```