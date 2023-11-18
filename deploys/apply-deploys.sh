#!/bin/bash

echo "****************************************"
echo "applying deploys"
echo "$POD_TEMPLATE_DIR"
echo "****************************************"

POD_TEMPLATE_FILE="$POD_TEMPLATE_DIR/pyspark-work-spark-jn.yml"

envsubst < $POD_TEMPLATE_FILE > $POD_DEFINITION_FILE

# Deploy the namespace
microk8s kubectl apply -f "$DEPLOY_DIR/namespace-pyspark-work.yaml"

# Deploy the pod
microk8s kubectl apply -f $POD_DEFINITION_FILE

echo "****************************************"
echo "deploy applications complete"
echo "****************************************"