#!/bin/bash
# Debug Cloudflare API Token

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -z "$TF_VAR_cloudflare_api_token" ]; then
    echo -e "${RED}Error: No token found in environment${NC}"
    exit 1
fi

TOKEN="${CLOUDFLARE_API_TOKEN:-$TF_VAR_cloudflare_api_token}"

echo "=== Token Debug Info ==="
echo "Token length: ${#TOKEN} characters"
echo "Token starts with: ${TOKEN:0:10}..."
echo ""

echo "=== 1. Verifying Token ==="
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq '.' || echo "$RESPONSE"
echo ""

ACCOUNT_ID=$(echo "$RESPONSE" | jq -r '.result.id // empty' 2>/dev/null || echo "")
if [ -z "$ACCOUNT_ID" ]; then
    ACCOUNT_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
fi

echo "Detected Account ID: $ACCOUNT_ID"
echo ""

echo "=== 2. Testing Workers Scripts API ==="
echo "Calling: GET /accounts/$ACCOUNT_ID/workers/scripts"
echo ""

FULL_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$FULL_RESPONSE" | tail -n1)
BODY=$(echo "$FULL_RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response body:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
echo ""

if [ "$HTTP_CODE" = "403" ]; then
    echo -e "${RED}=== 403 Error Analysis ===${NC}"
    echo ""
    echo "The token has the permission but Cloudflare is rejecting it."
    echo ""
    echo "Possible causes:"
    echo "1. Token was just created/updated - wait 1-2 minutes"
    echo "2. Account Resources scope issue - try recreating token"
    echo "3. Workers might not be enabled for this account"
    echo ""
    echo "Try:"
    echo "1. Wait 2 minutes and test again"
    echo "2. Create a NEW token (don't edit the existing one)"
    echo "3. Check if Workers is enabled: https://dash.cloudflare.com/workers"
fi
