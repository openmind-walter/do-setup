cd 01-Infra-setup
./setup-dev.sh
cd 02-post-eks-setup
./setup-dev.sh


# Check letsencrypt-prod ClusterIssuer
kubectl get ClusterIssuer -A  

# Check for certificates
kubectl describe certificates -n dev
kubectl describe certificaterequest -n dev

# If there is an error
  Normal  cert-manager.io     17m   cert-manager-certificaterequests-approver           Certificate request has been approved by cert-manager.io
  Normal  IssuerNotFound      17m   cert-manager-certificaterequests-issuer-vault       Referenced "ClusterIssuer" not found: clusterissuer.cert-manager.io "letsencrypt-prod" not found

# Then delete the cert request and cert
kubectl delete certificaterequest -n dev dev-events-tls-1
kubectl delete certificate -n dev dev-events-tls




Deployment
cd ../app-deployment
cd configs
./deploy_config.sh dev
cd ../deploy
./deploy_flyway.sh dev

