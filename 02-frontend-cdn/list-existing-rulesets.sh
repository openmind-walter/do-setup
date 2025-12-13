#!/bin/bash
# List existing rulesets for a zone

set -e

if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -z "$TF_VAR_cloudflare_api_token" ]; then
    echo "Error: No token found"
    exit 1
fi

TOKEN="${CLOUDFLARE_API_TOKEN:-$TF_VAR_cloudflare_api_token}"

ZONE_NAME="${1:-sb-demokit.com}"

echo "=== Getting Zone ID for $ZONE_NAME ==="
ZONES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

ZONE_ID=$(echo "$ZONES" | jq -r '.result[0].id // empty')
echo "Zone ID: $ZONE_ID"
echo ""

if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" = "null" ]; then
    echo "Error: Zone not found"
    exit 1
fi

echo "=== Listing All Rulesets ==="
RULESETS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo "$RULESETS" | jq '.result[] | {id, name, kind, phase, description}' | head -50

echo ""
echo "=== Rulesets with http_request_cache_settings phase ==="
echo "$RULESETS" | jq '.result[] | select(.phase == "http_request_cache_settings") | {id, name, kind, phase, description}'
