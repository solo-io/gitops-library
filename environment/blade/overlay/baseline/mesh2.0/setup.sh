#!/bin/bash

source ../../../base/mesh2.0/
sh install-istio.sh
sh install-bookinfo.sh
sh install-httpbin.sh
sh install-gloo-mesh.sh



