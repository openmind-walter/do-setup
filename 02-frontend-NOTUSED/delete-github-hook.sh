#!/bin/bash

# --- Configuration ---
# Your DigitalOcean Personal Access Token (must have 'read' and 'write' access to Apps)
# IMPORTANT: It is highly recommended to set this as an environment variable (export DO_TOKEN='...')
DO_TOKEN="${DO_TOKEN:-}"

# The name of your DigitalOcean App Platform application
APP_NAME="dev-sb"

# The name of the specific component (Static Site) to check
COMPONENT_NAME="mobile-openmindsolutions-sg" # Adjust if your component name is different from the app name

# --- Validation and Initialization ---

if [ -z "$DO_TOKEN" ]; then
    echo "Error: DO_TOKEN environment variable is not set." >&2
    echo "Please set your DigitalOcean Personal Access Token." >&2
    exit 1
fi

# Function to find App ID by name
get_app_id() {
    curl -s -X GET \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps?per_page=100" | \
    jq -r ".apps[] | select(.spec.name == \"$APP_NAME\") | .id"
}

# Function to find the component's source_spec
get_source_spec() {
    curl -s -X GET \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps/$1" | \
    jq -r ".app.spec.static_sites[] | select(.name == \"$COMPONENT_NAME\") | .github // .gitlab // empty"
}

# --- Main Logic ---

echo "Searching for App ID for '$APP_NAME'..."
APP_ID=$(get_app_id)

if [ -z "$APP_ID" ]; then
    echo "Error: App Platform application '$APP_NAME' not found." >&2
    exit 1
fi
echo "Found App ID: $APP_ID"

# 1. Get the current source spec to find the source ID
SOURCE_SPEC=$(get_source_spec "$APP_ID")

if [ -z "$SOURCE_SPEC" ]; then
    echo "Error: Could not find GitHub/GitLab source for component '$COMPONENT_NAME'." >&2
    exit 1
fi

# The webhook ID is usually the component ID or the source ID.
# Since the DO API doesn't expose the webhook ID directly via the app spec,
# we need to delete the source definition, which removes the webhook.
# NOTE: Deleting the source spec is usually a complex PUT operation that modifies the whole spec.

# --- Alternative (Easier): Use the 'doctl' CLI command ---
echo "Attempting to disable auto-deploy using doctl..."
# doctl supports turning off auto-deploy by updating the source spec
doctl apps update-source-spec "$APP_NAME" \
    --component "$COMPONENT_NAME" \
    --type static-site \
    --no-deploy-on-push

# 2. Re-fetch and verify the webhook status (often needed to fully disable)
# The surest way to remove the webhook is through GitHub/GitLab UI,
# but the 'doctl' command above should update the App Platform configuration.
echo ""
echo "Please verify on GitHub/GitLab that the webhook for the branch is disabled."
echo "If automatic deployments persist, the webhook must be manually deleted on GitHub/GitLab."