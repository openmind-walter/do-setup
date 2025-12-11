#!/bin/bash
# Script to check if GitHub is connected to DigitalOcean
# This is called before Terraform applies to provide helpful error messages

set -e

DO_TOKEN="${DO_TOKEN:-${TF_VAR_do_token}}"

if [ -z "$DO_TOKEN" ]; then
  echo "Error: DO_TOKEN or TF_VAR_do_token not set"
  exit 1
fi

echo "Checking GitHub connection to DigitalOcean..."

# Check if we can list apps (this will fail if GitHub is not connected when trying to create an app with GitHub source)
# We'll try to get integration info via API
INTEGRATIONS=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_TOKEN" \
  "https://api.digitalocean.com/v2/integrations" 2>/dev/null || echo "{}")

GITHUB_CONNECTED=$(echo "$INTEGRATIONS" | jq -r '.integrations[]? | select(.provider == "github") | .provider // empty' 2>/dev/null || echo "")

if [ -n "$GITHUB_CONNECTED" ]; then
  echo "✅ GitHub is connected to DigitalOcean"
  echo ""
  GITHUB_ACCOUNT=$(echo "$INTEGRATIONS" | jq -r '.integrations[]? | select(.provider == "github") | .account_name // "Unknown"' 2>/dev/null || echo "Unknown")
  echo "Connected GitHub account: $GITHUB_ACCOUNT"
  exit 0
else
  echo "❌ GitHub is NOT connected to DigitalOcean"
  echo ""
  echo "To connect GitHub:"
  echo "1. Go to: https://cloud.digitalocean.com/account/api/integrations"
  echo "2. Click 'Connect GitHub'"
  echo "3. Authorize DigitalOcean to access your GitHub repositories"
  echo "4. Grant access to repository: openmind-walter/dummy-fe"
  echo ""
  echo "After connecting, run this script again to verify."
  exit 1
fi

