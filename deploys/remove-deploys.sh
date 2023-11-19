#!/bin/bash

# Define the directory where the deploy files are located
DEPLOY_DIR="$(pwd)/deploys"
POD_TEMPLATE_DIR="$DEPLOY_DIR/templates"

# Path to the namespace and pod definition files
NAMESPACE_FILE="$DEPLOY_DIR/namespace-pyspark-work.yaml"
POD_DEFINITION_FILE="$DEPLOY_DIR/pyspark-work-spark-jn.yml"

echo "****************************************"
echo "Destroying deployed resources"
echo "****************************************"

# Delete the pod
microk8s kubectl delete -f $POD_DEFINITION_FILE

# Delete the namespace
microk8s kubectl delete -f $NAMESPACE_FILE

echo "****************************************"
echo "Resource destruction complete"
echo "****************************************"
