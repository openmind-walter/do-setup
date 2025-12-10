#!/bin/bash
# get-nginx-ip.sh

NAMESPACE="$1"
SERVICE_NAME="${NAMESPACE}-nginx-ingress-controller"

IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Output as JSON for Terraform external data source
echo "{\"ip\": \"$IP\"}"
