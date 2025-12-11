if [[ -z "$1" ]]; then
  echo "$0 <cluster>"
  exit 0
fi
export CLUSTER=$1
# Must configure aws cli with DigitalOcean Spaces credentials
# aws configure
# Use:
# Access Key → DO Spaces Access Key
# Secret Key → DO Spaces Secret Key
# Region → us-east-1 (doesn’t matter, DO ignores it)

aws --endpoint-url https://sgp1.digitaloceanspaces.com \
    s3api create-bucket \
    --bucket ${CLUSTER}-terraform-phoenix \
    --region us-east-1

