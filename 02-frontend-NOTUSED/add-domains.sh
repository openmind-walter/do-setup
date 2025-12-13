#!/bin/bash
# Script to add custom domains to DigitalOcean App Platform app
# Usage: ./add-domains.sh <APP_ID> <DO_TOKEN> <DOMAINS_JSON>
#   or: ./add-domains.sh <APP_ID> <DO_TOKEN> --from-tfvars <TFVARS_FILE>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to print warning
warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

# Function to print success
success() {
    echo -e "${GREEN}$1${NC}"
}

# Check if required tools are installed
command -v jq >/dev/null 2>&1 || error_exit "jq is required but not installed. Install with: brew install jq"
command -v curl >/dev/null 2>&1 || error_exit "curl is required but not installed"

# Parse arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <APP_ID> <DO_TOKEN> <DOMAINS_JSON>"
    echo "   or: $0 <APP_ID> <DO_TOKEN> --from-tfvars <TFVARS_FILE>"
    echo ""
    echo "Examples:"
    echo "  $0 app-123 token '{\"domains\":[{\"domain\":\"example.com\",\"type\":\"PRIMARY\"}]}'"
    echo "  $0 app-123 token --from-tfvars ../00-Env/dev.frontend.tfvars"
    exit 1
fi

APP_ID="$1"
DO_TOKEN="$2"

if [ -z "$APP_ID" ] || [ -z "$DO_TOKEN" ]; then
    error_exit "APP_ID and DO_TOKEN are required"
fi

# Determine how to get domains
if [ "$3" = "--from-tfvars" ] && [ -n "$4" ]; then
    # Extract domains from tfvars file
    TFVARS_FILE="$4"
    if [ ! -f "$TFVARS_FILE" ]; then
        error_exit "TFVARS file not found: $TFVARS_FILE"
    fi
    
    echo "Extracting domains from $TFVARS_FILE..."
    # Parse tfvars to extract site_configs and build domains array
    # Extract domain_name values from site_configs blocks
    # First, extract all domain_name values into a temp file
    TEMP_DOMAINS=$(mktemp)
    grep -A 100 "site_configs" "$TFVARS_FILE" | \
        grep -E "^\s*domain_name\s*=" | \
        sed -E 's/.*domain_name[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/' > "$TEMP_DOMAINS" 2>/dev/null || true
    
    # Check if we found any domains
    if [ ! -s "$TEMP_DOMAINS" ]; then
        rm -f "$TEMP_DOMAINS"
        error_exit "Could not extract domains from $TFVARS_FILE. Make sure site_configs contains domain_name entries."
    fi
    
    # Build JSON array from domains using jq
    DOMAINS_JSON=$(jq -nR '[inputs | select(length > 0) | {"domain": ., "type": "PRIMARY"}]' "$TEMP_DOMAINS")
    rm -f "$TEMP_DOMAINS"
    
    if [ -z "$DOMAINS_JSON" ] || [ "$DOMAINS_JSON" = "[]" ]; then
        error_exit "Could not build domains JSON from $TFVARS_FILE"
    fi
elif [ "$3" = "--from-terraform" ]; then
    # Extract from Terraform state/output
    echo "Extracting domains from Terraform..."
    # This would require terraform to be run first
    # For now, we'll use a helper approach
    error_exit "Please use --from-tfvars or provide domains JSON directly"
else
    # Use provided domains JSON
    DOMAINS_JSON="$3"
    if [ -z "$DOMAINS_JSON" ]; then
        error_exit "DOMAINS_JSON is required (or use --from-tfvars)"
    fi
    
    # Validate it's valid JSON
    if ! echo "$DOMAINS_JSON" | jq . >/dev/null 2>&1; then
        error_exit "DOMAINS_JSON is not valid JSON"
    fi
fi

echo "Adding custom domains to app $APP_ID..."
echo "Domains to add:"
echo "$DOMAINS_JSON" | jq -r '.[] | "  - \(.domain) (\(.type))"'

# Use temporary files to avoid shell variable issues
TEMP_APP_DATA=$(mktemp)
TEMP_SPEC=$(mktemp)
TEMP_REQUEST=$(mktemp)
TEMP_RESPONSE=$(mktemp)

# Cleanup function
cleanup() {
    rm -f "$TEMP_APP_DATA" "$TEMP_SPEC" "$TEMP_REQUEST" "$TEMP_RESPONSE"
}
trap cleanup EXIT

# Get current app spec and check deployment status
echo "Fetching current app spec..."
TEMP_GET_RESPONSE=$(mktemp)
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TEMP_APP_DATA" -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DO_TOKEN" \
    "https://api.digitalocean.com/v2/apps/$APP_ID")

if [ "$HTTP_CODE" -lt 200 ] || [ "$HTTP_CODE" -ge 300 ]; then
    echo "API Response (HTTP $HTTP_CODE):"
    cat "$TEMP_APP_DATA" | jq . 2>/dev/null || cat "$TEMP_APP_DATA"
    rm -f "$TEMP_GET_RESPONSE"
    error_exit "Failed to fetch app spec (HTTP $HTTP_CODE)"
fi
rm -f "$TEMP_GET_RESPONSE"

# Check app deployment status
APP_STATUS=$(jq -r '.app.last_deployment_active_at // empty' "$TEMP_APP_DATA" 2>/dev/null || echo "")
LIVE_URL=$(jq -r '.app.live_url // empty' "$TEMP_APP_DATA" 2>/dev/null || echo "")
ACTIVE_DEPLOYMENT=$(jq -r '.app.active_deployment.id // empty' "$TEMP_APP_DATA" 2>/dev/null || echo "")
DEPLOYMENT_PHASE=$(jq -r '.app.active_deployment.phase // empty' "$TEMP_APP_DATA" 2>/dev/null || echo "")

echo "App Status:"
echo "  Live URL: $LIVE_URL"
echo "  Last Deployment: $APP_STATUS"
echo "  Active Deployment: $ACTIVE_DEPLOYMENT"
echo "  Deployment Phase: $DEPLOYMENT_PHASE"
echo ""

if [ -z "$LIVE_URL" ] || [ "$LIVE_URL" = "null" ] || [ "$LIVE_URL" = "" ]; then
    warning "App does not have a live_url yet. This usually means the app is not fully deployed."
    echo ""
    echo "Domains can only be configured after the app is successfully deployed and has a live_url."
    echo "Please wait for the deployment to complete, then run this script again."
    echo ""
    echo "You can check the deployment status in the DigitalOcean console:"
    echo "  https://cloud.digitalocean.com/apps/$APP_ID"
    echo ""
    error_exit "App is not ready for domain configuration"
fi

if [ -n "$DEPLOYMENT_PHASE" ] && [ "$DEPLOYMENT_PHASE" != "ACTIVE" ] && [ "$DEPLOYMENT_PHASE" != "SUPERSEDED" ]; then
    warning "Deployment is in phase: $DEPLOYMENT_PHASE (not ACTIVE)"
    echo "The app may still be deploying. Domains might not be configurable yet."
    echo ""
fi

# Extract spec - handle it as JSON value (could be object or JSON-encoded string)
SPEC_TYPE=$(jq -r 'type(.app.spec)' "$TEMP_APP_DATA" 2>/dev/null || echo "null")

if [ "$SPEC_TYPE" = "string" ]; then
    # Spec is a JSON-encoded string, parse it
    jq -c '.app.spec | fromjson | if . == null then {} else . end' "$TEMP_APP_DATA" > "$TEMP_SPEC" 2>/dev/null || echo "{}" > "$TEMP_SPEC"
elif [ "$SPEC_TYPE" = "object" ]; then
    # Spec is already an object
    jq -c '.app.spec | if . == null then {} else . end' "$TEMP_APP_DATA" > "$TEMP_SPEC" 2>/dev/null || echo "{}" > "$TEMP_SPEC"
elif [ "$SPEC_TYPE" = "null" ]; then
    # Spec is null, use empty object
    echo "{}" > "$TEMP_SPEC"
else
    # Fallback: create empty spec
    echo "{}" > "$TEMP_SPEC"
fi

# Ensure we have valid JSON object (not null or empty)
# Normalize the spec to always be a valid object
if [ ! -s "$TEMP_SPEC" ]; then
    echo "{}" > "$TEMP_SPEC"
else
    # Validate and normalize: if it's null or not an object, make it {}
    jq -c 'if . == null or type != "object" then {} else . end' "$TEMP_SPEC" > "$TEMP_SPEC.valid" 2>/dev/null || echo "{}" > "$TEMP_SPEC.valid"
    mv "$TEMP_SPEC.valid" "$TEMP_SPEC"
fi

# Final verification
if ! jq -e 'type == "object"' "$TEMP_SPEC" >/dev/null 2>&1; then
    warning "Spec file is invalid after normalization, using empty spec"
    echo "{}" > "$TEMP_SPEC"
fi

# Merge domains into spec
echo "Merging domains into spec..."
# Normalize domains JSON to array format
DOMAINS_ARRAY=$(echo "$DOMAINS_JSON" | jq 'if type == "array" then . else [.] end')

# Debug: Show current spec before merge
echo "Current spec structure:"
jq 'keys' "$TEMP_SPEC" 2>/dev/null || echo "  (empty or invalid)"

# Merge domains into spec - preserve all existing fields
jq --argjson domains "$DOMAINS_ARRAY" '
    # Ensure we have an object
    (if . == null or type != "object" then {} else . end) |
    # Merge domains while preserving all other fields
    . + {
        domains: ((.domains // []) + $domains | unique_by(.domain))
    }
' "$TEMP_SPEC" > "$TEMP_SPEC.merged" 2>/dev/null || {
    error_exit "Failed to merge domains into spec"
}

# Verify the merged spec has required fields
if ! jq -e '.name' "$TEMP_SPEC.merged" >/dev/null 2>&1; then
    warning "Spec is missing 'name' field. Attempting to get from app data..."
    # Try to get name from the app data
    APP_NAME=$(jq -r '.app.spec.name // .app.name // empty' "$TEMP_APP_DATA" 2>/dev/null || echo "")
    if [ -n "$APP_NAME" ]; then
        jq --arg name "$APP_NAME" '. + {name: $name}' "$TEMP_SPEC.merged" > "$TEMP_SPEC.merged.tmp"
        mv "$TEMP_SPEC.merged.tmp" "$TEMP_SPEC.merged"
    else
        error_exit "Cannot determine app name. The spec must include 'name' field."
    fi
fi

# Verify region is present
if ! jq -e '.region' "$TEMP_SPEC.merged" >/dev/null 2>&1; then
    warning "Spec is missing 'region' field. Attempting to get from app data..."
    APP_REGION=$(jq -r '.app.spec.region // .app.region // empty' "$TEMP_APP_DATA" 2>/dev/null || echo "")
    if [ -n "$APP_REGION" ]; then
        jq --arg region "$APP_REGION" '. + {region: $region}' "$TEMP_SPEC.merged" > "$TEMP_SPEC.merged.tmp"
        mv "$TEMP_SPEC.merged.tmp" "$TEMP_SPEC.merged"
    else
        error_exit "Cannot determine app region. The spec must include 'region' field."
    fi
fi

mv "$TEMP_SPEC.merged" "$TEMP_SPEC"

# Update app spec - use the merged spec from temp file
echo "Updating app spec..."
jq -c '{spec: .}' "$TEMP_SPEC" > "$TEMP_REQUEST"

# Debug: Show what we're sending (first 500 chars)
echo "Request preview (first 500 chars):"
head -c 500 "$TEMP_REQUEST" | jq . 2>/dev/null || head -c 500 "$TEMP_REQUEST"
echo ""

# Make the API call and capture response
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TEMP_RESPONSE" -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DO_TOKEN" \
    -d @"$TEMP_REQUEST" \
    "https://api.digitalocean.com/v2/apps/$APP_ID")

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    success "✅ Successfully updated app spec with domains"
    echo ""
    
    # Verify domains were added by fetching the app again
    echo "Verifying domains were added..."
    sleep 2  # Give API a moment to process
    curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps/$APP_ID" > "$TEMP_APP_DATA"
    
    CURRENT_DOMAINS=$(jq -r '.app.spec.domains[]? | "\(.domain) (\(.type))"' "$TEMP_APP_DATA" 2>/dev/null || echo "")
    
    if [ -n "$CURRENT_DOMAINS" ]; then
        echo "Domains currently configured in app:"
        echo "$CURRENT_DOMAINS" | while read -r domain; do
            echo "  - $domain"
        done
        echo ""
        success "✅ Domains have been successfully added to the app!"
        echo ""
        echo "Next steps:"
        echo "1. Wait a few minutes for the changes to propagate"
        echo "2. Check the App Platform console: https://cloud.digitalocean.com/apps/$APP_ID/settings"
        echo "3. Ensure DNS CNAME records are configured (Terraform should handle this)"
    else
        warning "Domains were updated in the spec, but could not verify they were added."
        echo "Please check the App Platform console to confirm:"
        echo "  https://cloud.digitalocean.com/apps/$APP_ID/settings"
    fi
    
    rm -f "$TEMP_RESPONSE"
else
    echo "API Response (HTTP $HTTP_CODE):"
    cat "$TEMP_RESPONSE" | jq . 2>/dev/null || cat "$TEMP_RESPONSE"
    echo ""
    echo "Request that was sent:"
    cat "$TEMP_REQUEST" | jq . 2>/dev/null || cat "$TEMP_REQUEST"
    rm -f "$TEMP_RESPONSE"
    error_exit "Failed to add domains (HTTP $HTTP_CODE). See details above."
fi

