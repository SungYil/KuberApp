#!/bin/bash

AWSSECRET=${1:-k8s.external.secrets}
NAMESPACE=${2:-external-secrets}

ACCESSKEY=$(aws secretsmanager get-secret-value --secret-id ${AWSSECRET} --query SecretString --output text | jq -r ".accesskey")
SECRETKEY=$(aws secretsmanager get-secret-value --secret-id ${AWSSECRET} --query SecretString --output text | jq -r ".secretkey")

kubectl create secret generic aws-secret --namespace ${NAMESPACE} \
    --from-literal=accesskey=${ACCESSKEY} \
    --from-literal=secretkey=${SECRETKEY}

cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: secretstore-aws
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-northeast-2
      auth:
        secretRef:
          accessKeyIDSecretRef:
            namespace: ${NAMESPACE}
            name: aws-secret
            key: accesskey
          secretAccessKeySecretRef:
            namespace: ${NAMESPACE}
            name: aws-secret
            key: secretkey
EOF