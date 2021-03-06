#!/bin/sh

set -eu

echo "Saving certificates to file system ..."

mkdir -p /cockroach/cockroach-certs

echo "${DB_CA_CRT}" | base64 --decode --ignore-garbage > /cockroach/cockroach-certs/ca.crt
echo "${DB_NODE_CRT}" | base64 --decode --ignore-garbage > /cockroach/cockroach-certs/node.crt
echo "${DB_NODE_KEY}" | base64 --decode --ignore-garbage > /cockroach/cockroach-certs/node.key

chmod 0600 /cockroach/cockroach-certs/node.key

echo "Starting cockroach $FLY_APP_NAME cluster..."

exec /cockroach/cockroach start \
  --logtostderr \
  --certs-dir=/cockroach/cockroach-certs \
  --locality=region=$FLY_REGION \
  --cluster-name=$FLY_APP_NAME \
  --join=$FLY_APP_NAME.internal \
  --advertise-addr=$(hostname -s).vm.$FLY_APP_NAME.internal \
  --http-addr 0.0.0.0
