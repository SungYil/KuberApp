#!/bin/bash

HOSTNAME=${1:-$(kubectl config view -o jsonpath='{.clusters[].name}')}
AWSSECRET=${2:-clever.datadog.test}

API_KEY=$(aws secretsmanager get-secret-value --secret-id ${AWSSECRET} --query SecretString --output text | jq -r ".DATADOG_API_KEY")
SITE=$(aws secretsmanager get-secret-value --secret-id ${AWSSECRET} --query SecretString --output text | jq -r ".DATADOG_SITE")
APP_KEY=$(aws secretsmanager get-secret-value --secret-id ${AWSSECRET} --query SecretString --output text | jq -r ".DATADOG_APP_KEY")

echo ${HOSTNAME}
echo ${API_KEY}
echo ${SITE}

helm repo add --force-update datadog https://helm.datadoghq.com
helm repo update
helm install -f ./values-datadog.yaml datadog datadog/datadog
    