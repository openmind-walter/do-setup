#!/bin/bash
# Test Cloudflare API Token Permissions
# This script helps verify if your API token has the required permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing Cloudflare API Token Permissions..."
echo ""

# Check if token is set
if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -z "$TF_VAR_cloudflare_api_token" ]; then
    echo -e "${RED}Error: CLOUDFLARE_API_TOKEN or TF_VAR_cloudflare_api_token not set${NC}"
    echo "Set it with: export CLOUDFLARE_API_TOKEN='your_token_here'"
    exit 1
fi

TOKEN="${CLOUDFLARE_API_TOKEN:-$TF_VAR_cloudflare_api_token}"

# Test 1: Verify token is valid
echo "1. Testing token validity..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Token is valid${NC}"
    # Extract account ID and email from response
    ACCOUNT_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    EMAIL=$(echo "$BODY" | grep -o '"email":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    echo "  Account ID: $ACCOUNT_ID"
    echo "  Email: $EMAIL"
else
    echo -e "${RED}✗ Token is invalid (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    exit 1
fi

echo ""

# Test 2: List zones (requires Zone: Read)
echo "2. Testing Zone: Read permission..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Zone: Read permission OK${NC}"
    ZONE_COUNT=$(echo "$BODY" | grep -o '"id":"[^"]*"' | wc -l | tr -d ' ')
    echo "  Found $ZONE_COUNT zone(s)"
    
    # Extract first zone ID for testing
    FIRST_ZONE_ID=$(echo "$BODY" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    if [ -n "$FIRST_ZONE_ID" ]; then
        echo "  Using zone ID: $FIRST_ZONE_ID for further tests"
    fi
else
    echo -e "${RED}✗ Zone: Read permission missing (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
    FIRST_ZONE_ID=""
fi

echo ""

# Test 3: List rulesets (requires Zone Rulesets: Read/Edit)
if [ -n "$FIRST_ZONE_ID" ]; then
    echo "3. Testing Zone Rulesets permission..."
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "https://api.cloudflare.com/client/v4/zones/$FIRST_ZONE_ID/rulesets" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json")
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Zone Rulesets permission OK${NC}"
        RULESET_COUNT=$(echo "$BODY" | grep -o '"id":"[^"]*"' | wc -l | tr -d ' ')
        echo "  Found $RULESET_COUNT ruleset(s) in zone"
    elif [ "$HTTP_CODE" = "403" ]; then
        echo -e "${RED}✗ Zone Rulesets permission MISSING (HTTP 403)${NC}"
        echo -e "${YELLOW}  This is the permission you need to add!${NC}"
        echo "  Go to: https://dash.cloudflare.com/profile/api-tokens"
        echo "  Edit your token and add: Zone → Zone Rulesets → Edit"
    else
        echo -e "${YELLOW}⚠ Unexpected response (HTTP $HTTP_CODE)${NC}"
        echo "$BODY"
    fi
else
    echo -e "${YELLOW}⚠ Skipping rulesets test (no zone ID available)${NC}"
fi

echo ""

# Test 4: Workers Scripts (requires Account: Workers Scripts: Edit)
echo "4. Testing Workers Scripts permission..."
echo "  Testing against Account ID: $ACCOUNT_ID"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ Workers Scripts permission OK${NC}"
elif [ "$HTTP_CODE" = "403" ]; then
    echo -e "${RED}✗ Workers Scripts permission MISSING (HTTP 403)${NC}"
    echo ""
    echo -e "${YELLOW}Possible issues:${NC}"
    echo "  1. Token doesn't have 'Account → Workers Scripts → Edit' permission"
    echo "  2. Account Resources doesn't include Account ID: $ACCOUNT_ID"
    echo "     → Go to token settings and ensure 'Account Resources' includes this account"
    echo "     → Or select 'All accounts'"
    echo ""
    echo "  Fix: Edit token at https://dash.cloudflare.com/profile/api-tokens"
    echo "       Under 'Account Resources', select 'Include' → 'All accounts'"
    echo "       OR select 'Include' → 'Specific account' → '$ACCOUNT_ID'"
else
    echo -e "${YELLOW}⚠ Unexpected response (HTTP $HTTP_CODE)${NC}"
    echo "$BODY"
fi

echo ""
echo "=== Summary ==="
echo "If you see any ✗ marks above, you need to add those permissions to your API token."
echo "Edit your token at: https://dash.cloudflare.com/profile/api-tokens"

