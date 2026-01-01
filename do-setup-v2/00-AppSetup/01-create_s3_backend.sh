if [[ -z "$1" ]]; then
  echo "$0 <app>"
  exit 0
fi
#export CLUSTER=$1
export APP_NAME=$1
# Must configure aws cli with DigitalOcean Spaces credentials
# aws configure
# Use:
# Access Key → DO Spaces Access Key
# Secret Key → DO Spaces Secret Key
# Region → us-east-1 (doesn’t matter, DO ignores it)
# echo aws --endpoint-url https://syd1.digitaloceanspaces.com s3api create-bucket --bucket ${APP}   --region us-east-1
# aws --endpoint-url https://syd1.digitaloceanspaces.com s3api create-bucket --bucket ${APP}   --region us-east-1

aws s3 mb s3://${APP_NAME} --endpoint-url https://syd1.digitaloceanspaces.com   --region syd1
