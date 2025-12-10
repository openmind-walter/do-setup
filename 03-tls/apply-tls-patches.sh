#!/bin/bash

# Apply the ClusterIssuer
echo "Applying ClusterIssuer..."
kubectl apply -f cluster-issuer.yaml

# Wait for ClusterIssuer to be ready
echo "Waiting for ClusterIssuer to be ready..."
kubectl wait --for=condition=Ready clusterissuer/letsencrypt-staging --timeout=60s

# Apply the Certificate
echo "Applying Certificate..."
kubectl apply -f certificate.yaml

# Wait for Certificate to be ready
echo "Waiting for Certificate to be ready..."
kubectl wait --for=condition=Ready certificate/dev-events-tls -n dev --timeout=300s

# Apply the Nginx Ingress Controller service patch
echo "Applying Nginx Ingress Controller service patch..."
kubectl patch svc dev-nginx-ingress-controller -n dev --patch-file=nginx-ingress-patch.yaml

# Apply the ingress patch
echo "Applying ingress patch..."
kubectl patch ingress dev-openmindsolutions-sg-master -n dev --patch-file=ingress-patch.yaml

echo "TLS patches applied successfully!" 