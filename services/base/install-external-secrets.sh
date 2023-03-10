#!/bin/bash

NAME=${1:-external-secrets}
NAMESPACE=${2:-external-secrets}

helm repo add --force-update external-secrets https://charts.external-secrets.io
helm repo update
helm install ${NAME} external-secrets/external-secrets --namespace ${NAMESPACE} --create-namespace --set installCRDs=true --version 0.5.8