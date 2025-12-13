if [[ -z "$1" ]]; then
  echo "./destroy.sh <cluster_name>"
  exit 0
fi
CLUSTER_NAME=$1
cp ../00-Env/variables.tf symbolic_link.variables.tf
cp ../00-Env/shared.tf symbolic_link.shared.tf
cp ../00-Env/provider.tf symbolic_link.provider.tf
cp ../00-Env/${CLUSTER_NAME}.provider.tf symbolic_link.${CLUSTER_NAME}.provider.tf
cp ../00-Env/${CLUSTER_NAME}.tfvars symbolic_link.${CLUSTER_NAME}.tfvars
cp ../00-Env/${CLUSTER_NAME}.frontend.tfvars symbolic_link.${CLUSTER_NAME}.frontend.tfvars
terraform init
# terraform workspace select ${CLUSTER_NAME}
# if [ $? -eq 0 ]; then
#   echo "Workspace ${CLUSTER_NAME}"
  terraform destroy -var-file=symbolic_link.${CLUSTER_NAME}.tfvars -var-file=symbolic_link.${CLUSTER_NAME}.frontend.tfvars 

# else
#   echo "workspace ${CLUSTER_NAME} does not exists"
#   echo "to create workspace use: terraform workspace new ${CLUSTER_NAME}"
# fi
