#!/bin/bash

NAMESPACE=${1:-mongodb}
EXPIRY=${2:-876000h} # 100y
CLUSTER_NAME=${3:-mongodb}
TARGET_SERVICE=${4:-mongodb}

OUTPUT_PATH=./outputs/ca/${mongodb}

kubectl delete issuers.cert-manager mongodb-psmdb-ca -n mongodb
kubectl delete certificates.cert-manager.io mongodb-ssl -n mongodb
kubectl delete certificates.cert-manager.io mongodb-ssl-internal -n mongodb

kubectl delete secret ${CLUSTER_NAME}-ssl-internal -n ${NAMESPACE}
kubectl delete secret ${CLUSTER_NAME}-ssl -n ${NAMESPACE}

mkdir -p ${OUTPUT_PATH}

cd ${OUTPUT_PATH}

# Root CA
cat <<EOF | cfssl gencert -initca - | cfssljson -bare ca
  {
    "CA": {
      "expiry": "${EXPIRY}",
      "pathlen": 0
    },
    "CN": "Root CA",
    "names": [
      {
        "O": "PSMDB"
      }
    ],
    "key": {
      "algo": "rsa",
      "size": 2048
    }
  }

EOF



# config

cat <<EOF >ca-config.json
  {
    "signing": {
      "default": {
        "expiry": "${EXPIRY}",
        "usages": ["signing", "key encipherment", "server auth", "client auth"]
      }
    }
  }

EOF



# server

cat <<EOF | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=./ca-config.json - | cfssljson -bare server

  {
    "hosts": [
      "localhost",
      "${CLUSTER_NAME}-rs0",
      "${CLUSTER_NAME}-rs0.${NAMESPACE}",
      "${CLUSTER_NAME}-rs0.${NAMESPACE}.svc.cluster.local",
      "*.${CLUSTER_NAME}-rs0",
      "*.${CLUSTER_NAME}-rs0.${NAMESPACE}",
      "*.${CLUSTER_NAME}-rs0.${NAMESPACE}.svc.cluster.local",
      "mongodb-rs0.mongodb.svc.clusterset.local",
      "*.mongodb-rs0.mongodb.svc.clusterset.local",
      "*.mongodb.svc.clusterset.local",
      "mongodb-mongos",
      "mongodb-mongos.mongodb",
      "mongodb-mongos.mongodb.svc.cluster.local",
      "*.mongodb-mongos",
      "*.mongodb-mongos.mongodb",
      "*.mongodb-mongos.mongodb.svc.cluster.local",
      "mongodb-cfg",
      "mongodb-cfg.mongodb",
      "mongodb-cfg.mongodb.svc.cluster.local",
      "*.mongodb-cfg",
      "*.mongodb-cfg.mongodb",
      "*.mongodb-cfg.mongodb.svc.cluster.local",
      "mongodb-mongos.mongodb.svc.clusterset.local",
      "*.mongodb-mongos.mongodb.svc.clusterset.local",
      "mongodb-cfg.mongodb.svc.clusterset.local",
      "*.mongodb-cfg.mongodb.svc.clusterset.local"
    ],

    "names": [
      {
        "O": "psmdb"
      }
    ],

    "CN": "${CLUSTER_NAME/-rs0/}",

    "key": {
      "algo": "rsa",
      "size": 2048
    }

  }

EOF

cfssl bundle -ca-bundle=ca.pem -cert=server.pem | cfssljson -bare server
kubectl create secret generic ${CLUSTER_NAME}-ssl-internal -n ${NAMESPACE} --from-file=tls.crt=server.pem --from-file=tls.key=server-key.pem --from-file=ca.crt=ca.pem --type=kubernetes.io/tls

# client
cat <<EOF | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=./ca-config.json - | cfssljson -bare client

  {
    "hosts": [
      "localhost",
      "${CLUSTER_NAME}-rs0",
      "${CLUSTER_NAME}-rs0.${NAMESPACE}",
      "${CLUSTER_NAME}-rs0.${NAMESPACE}.svc.cluster.local",
      "*.${CLUSTER_NAME}-rs0",
      "*.${CLUSTER_NAME}-rs0.${NAMESPACE}",
      "*.${CLUSTER_NAME}-rs0.${NAMESPACE}.svc.cluster.local",
      "mongodb-rs0.mongodb.svc.clusterset.local",
      "*.mongodb-rs0.mongodb.svc.clusterset.local",
      "*.mongodb.svc.clusterset.local",
      "mongodb-mongos",
      "mongodb-mongos.mongodb",
      "mongodb-mongos.mongodb.svc.cluster.local",
      "*.mongodb-mongos",
      "*.mongodb-mongos.mongodb",
      "*.mongodb-mongos.mongodb.svc.cluster.local",
      "mongodb-cfg",
      "mongodb-cfg.mongodb",
      "mongodb-cfg.mongodb.svc.cluster.local",
      "*.mongodb-cfg",
      "*.mongodb-cfg.mongodb",
      "*.mongodb-cfg.mongodb.svc.cluster.local",
      "mongodb-mongos.mongodb.svc.clusterset.local",
      "*.mongodb-mongos.mongodb.svc.clusterset.local",
      "mongodb-cfg.mongodb.svc.clusterset.local",
      "*.mongodb-cfg.mongodb.svc.clusterset.local"
    ],

    "names": [
      {
        "O": "psmdb"
      }
    ],

    "CN": "${CLUSTER_NAME/-rs0/}",
    "key": {
      "algo": "rsa",
      "size": 2048
    }
  }
EOF

kubectl create secret generic ${CLUSTER_NAME}-ssl -n ${NAMESPACE} --from-file=tls.crt=client.pem --from-file=tls.key=client-key.pem --from-file=ca.crt=ca.pem --type=kubernetes.io/tls

# check expiry

{
  kubectl -n ${NAMESPACE} get secret/${CLUSTER_NAME}-ssl-internal -o jsonpath='{.data.tls\.crt}' | base64 --decode | openssl x509 -noout -dates
  kubectl -n ${NAMESPACE} get secret/${CLUSTER_NAME}-ssl -o jsonpath='{.data.ca\.crt}' | base64 --decode | openssl x509 -noout -dates
}

kubectl delete pods -n mongodb --all

# clean up
cd ..
rm -rf ${OUTPUT_PATH}