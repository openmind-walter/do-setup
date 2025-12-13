#!/bin/bash
# Helper script to add domains to App Platform using Terraform outputs
# This script extracts the app ID and domains from Terraform and calls add-domains.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADD_DOMAINS_SCRIPT="$SCRIPT_DIR/add-domains.sh"
TFVARS_FILE="${1:-../00-Env/dev.frontend.tfvars}"

if [ ! -f "$ADD_DOMAINS_SCRIPT" ]; then
    echo "Error: add-domains.sh not found at $ADD_DOMAINS_SCRIPT"
    exit 1
fi

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "Error: Terraform not initialized. Run 'terraform init' first."
    exit 1
fi

# Get app ID from Terraform output
echo "Getting app ID from Terraform..."
APP_ID=$(terraform output -raw parent_app_id 2>/dev/null || echo "")

if [ -z "$APP_ID" ]; then
    echo "Error: Could not get app ID from Terraform. Make sure the app is created."
    echo "Run 'terraform apply' first, or provide APP_ID manually:"
    echo "  $0 <APP_ID>"
    exit 1
fi

# Get DO token from environment or terraform
DO_TOKEN="${DO_TOKEN:-$(terraform output -raw do_token 2>/dev/null || echo "")}"

if [ -z "$DO_TOKEN" ]; then
    echo "Error: DO_TOKEN not set. Set it as environment variable:"
    echo "  export DO_TOKEN=your_token"
    echo "  $0"
    exit 1
fi

echo "Using App ID: $APP_ID"
echo "Using TFVARS: $TFVARS_FILE"
echo ""

# Call the add-domains script
"$ADD_DOMAINS_SCRIPT" "$APP_ID" "$DO_TOKEN" --from-tfvars "$TFVARS_FILE"

