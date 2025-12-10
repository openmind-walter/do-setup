#!/bin/bash

# Replace with your actual cluster name and region
CLUSTER_NAME="dev-events"
REGION="sgp1"

echo "Downloading kubeconfig for cluster: $CLUSTER_NAME"
doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" 


