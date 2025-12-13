#!/bin/bash
# Check if Workers is enabled and get account info

set -e

if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -z "$TF_VAR_cloudflare_api_token" ]; then
    echo "Error: No token found"
    exit 1
fi

TOKEN="${CLOUDFLARE_API_TOKEN:-$TF_VAR_cloudflare_api_token}"

echo "=== Getting User/Account Info ==="
USER_INFO=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "$USER_INFO" | jq '.'
echo ""

ACCOUNT_ID=$(echo "$USER_INFO" | jq -r '.result.organizations[0].id // .result.accounts[0].id // empty' 2>/dev/null)

if [ -z "$ACCOUNT_ID" ]; then
    echo "=== Listing All Accounts ==="
    ACCOUNTS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json")
    
    echo "$ACCOUNTS" | jq '.'
    ACCOUNT_ID=$(echo "$ACCOUNTS" | jq -r '.result[0].id // empty' 2>/dev/null)
fi

echo ""
echo "Account ID: $ACCOUNT_ID"
echo ""

if [ -n "$ACCOUNT_ID" ]; then
    echo "=== Checking Workers Status ==="
    WORKERS_STATUS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json")
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json")
    
    echo "HTTP Status: $HTTP_CODE"
    echo "$WORKERS_STATUS" | jq '.'
    
    if [ "$HTTP_CODE" = "403" ]; then
        echo ""
        echo "⚠️  Workers API is returning 403"
        echo "This could mean:"
        echo "1. Workers is not enabled for this account"
        echo "2. The token doesn't have the right Account Resources scope"
        echo ""
        echo "Check: https://dash.cloudflare.com/workers"
        echo "If Workers is not enabled, you may need to enable it first."
    fi
fi
