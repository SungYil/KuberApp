#!/bin/bash

COMMAND=${1:-install}
MASTER_NODE=${2:-test1-0}
K8S_SERVICE_HOST=${3:-$(kubectl get nodes ${MASTER_NODE} -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')}
K8S_SERVICE_PORT=${4:-6443}

CILIUM_VERSION=${CILIUM_VERSION:-1.12.4}

DEBUG=${DEBUG:-true}
IPAM_MODE=${IPAM_MODE:-cluster-pool}

helm repo add --force-update cilium https://helm.cilium.io
helm repo update
helm ${COMMAND} cilium cilium/cilium --version ${CILIUM_VERSION} \
    --namespace kube-system \
    --set debug.enabled=${DEBUG} \
    --set k8sServiceHost=${K8S_SERVICE_HOST} \
    --set k8sServicePort=${K8S_SERVICE_PORT} \
    --set tunnel=disabled \
    --set ipam.mode=${IPAM_MODE} \
    --set ipam.operator.clusterPoolIPv4PodCIDR=10.0.0.0/8 \
    --set ipam.operator.clusterPoolIPv4MaskSize=24 \
    --set kubeProxyReplacement=strict \
    --set autoDirectNodeRoutes=true \
    --set installIptablesRules=true \
    --set l7Proxy=false \
    --set enableCnpStatusUpdates=false \
    --set endpointRoutes.enabled=true \
    --set bpf.masquerade=true \
    --set masquerade=true \
    --set ipv4NativeRoutingCIDR=10.0.0.0/8 \
    --set localRedirectPolicy=true