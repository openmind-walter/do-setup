#!/bin/bash
# Test creating a ruleset via API to see exact error

set -e

if [ -z "$CLOUDFLARE_API_TOKEN" ] && [ -z "$TF_VAR_cloudflare_api_token" ]; then
    echo "Error: No token found"
    exit 1
fi

TOKEN="${CLOUDFLARE_API_TOKEN:-$TF_VAR_cloudflare_api_token}"

# Get zone ID for sb-demokit.com
echo "=== Getting Zone ID ==="
ZONES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=sb-demokit.com" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

ZONE_ID=$(echo "$ZONES" | jq -r '.result[0].id // empty')
echo "Zone ID: $ZONE_ID"
echo ""

if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" = "null" ]; then
    echo "Error: Zone not found"
    exit 1
fi

echo "=== Testing Ruleset Creation ==="
echo "Creating ruleset with phase: http_request_cache_settings"
echo ""

# Try to create a simple ruleset
PAYLOAD=$(cat <<JSON
{
  "name": "Test cache ruleset",
  "kind": "zone",
  "phase": "http_request_cache_settings",
  "rules": [
    {
      "description": "Test cache rule",
      "action": "set_cache_settings",
      "expression": "(http.host eq \"dev-admin.sb-demokit.com\")",
      "action_parameters": {
        "cache": true,
        "edge_ttl": {
          "mode": "override_origin",
          "default": 86400
        },
        "browser_ttl": {
          "mode": "override_origin",
          "default": 3600
        },
        "serve_stale": {
          "disable_stale_while_updating": false
        }
      }
    }
  ]
}
JSON
)

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/rulesets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo "Response:"
echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
