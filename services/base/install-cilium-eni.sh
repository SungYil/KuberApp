#!/bin/bash

MASTER_NODE=${2:-ip-192-168-20-119.ap-northeast-2.compute.internal}
K8S_SERVICE_HOST=${3:-$(kubectl get nodes ${MASTER_NODE} -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')}
K8S_SERVICE_PORT=${4:-6443}

helm repo add --force-update cilium https://helm.cilium.io
helm repo update
helm install cilium cilium/cilium --version 1.12.4 \
  --namespace kube-system \
  --set global.eni=true \
  --set k8sServiceHost=${K8S_SERVICE_HOST} \
  --set k8sServicePort=${K8S_SERVICE_PORT} \
  --set config.ipam.mode=eni \
  --set globalegressMasqueradeInterfaces=ens5 \
  --set global.tunnel=disabled \
  --set global.nodeinit.enabled=true \
  --set kubeProxyReplacement=strict