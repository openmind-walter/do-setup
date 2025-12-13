#!/bin/bash

# --- Configuration ---
# Your DigitalOcean Personal Access Token
DO_TOKEN="${DO_TOKEN:-}"

# The name of your DigitalOcean App Platform application
APP_NAME="dev-sb"

# The name of the specific component that you updated (e.g., 'site-a', 'docs')
# This is mainly for logging purposes.

# --- Validation and Initialization ---

if [ -z "$DO_TOKEN" ]; then
    echo "Error: DO_TOKEN environment variable is not set." >&2
    echo "Please set your DigitalOcean Personal Access Token." >&2
    exit 1
fi

# Function to find App ID by name (same as above)
get_app_id() {
    curl -s -X GET \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps?per_page=100" | \
    jq -r ".apps[] | select(.spec.name == \"$APP_NAME\") | .id"
}

# Function to get the latest deployment ID
get_latest_deployment_id() {
    curl -s -X GET \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps/$1/deployments?per_page=1" | \
    jq -r ".deployments[0].id"
}

# Function to get deployment status
get_deployment_status() {
    curl -s -X GET \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps/$1/deployments/$2" | \
    jq -r ".deployment.phase"
}

# --- Main Logic ---

echo "Searching for App ID for '$APP_NAME'..."
APP_ID=$(get_app_id)

if [ -z "$APP_ID" ]; then
    echo "Error: App Platform application '$APP_NAME' not found." >&2
    exit 1
fi
echo "Found App ID: $APP_ID"

echo "Triggering new deployment for App ID $APP_ID..."

# 1. Trigger the deployment via App Platform API
DEPLOY_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $DO_TOKEN" \
    "https://api.digitalocean.com/v2/apps/$APP_ID/deployments")

DEPLOYMENT_ID=$(echo "$DEPLOY_RESPONSE" | jq -r ".deployment.id // empty")

if [ -z "$DEPLOYMENT_ID" ] || [ "$DEPLOYMENT_ID" = "null" ]; then
    echo "Error: Failed to trigger deployment." >&2
    echo "Response: $DEPLOY_RESPONSE" >&2
    exit 1
fi

echo "✅ Deployment triggered successfully! Deployment ID: $DEPLOYMENT_ID"

# 2. Wait for deployment to complete
MAX_WAIT=900  # 15 minutes
WAIT_INTERVAL=15
ELAPSED=0

echo "Waiting for deployment to complete (max $MAX_WAIT seconds)..."
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(get_deployment_status "$APP_ID" "$DEPLOYMENT_ID")

    if [ "$STATUS" = "ACTIVE" ]; then
        echo "✅ Deployment completed successfully! Status: $STATUS"
        break
    elif [ "$STATUS" = "ERROR" ] || [ "$STATUS" = "CANCELED" ]; then
        echo "❌ Deployment failed with status: $STATUS" >&2
        exit 1
    fi

    echo "Status: $STATUS ($ELAPSED seconds elapsed)..."
    sleep $WAIT_INTERVAL
    ELAPSED=$((ELAPSED + WAIT_INTERVAL))
done

if [ "$STATUS" != "ACTIVE" ]; then
    echo "⚠️  Deployment timeout. Check the DigitalOcean console for status." >&2
    exit 1
fi