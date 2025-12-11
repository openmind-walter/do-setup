#!/bin/bash

# Script to add a static site component to DigitalOcean App Platform via API
# Usage: ./deploy-component.sh <app_id> <component_name> <domain_name> <source_dir>

set -e

APP_ID="${1:-}"
COMPONENT_NAME="${2:-mobile_openmindsolutions_sg}"
DOMAIN_NAME="${3:-dev-mobile.openmindsolutions.sg}"
SOURCE_DIR="${4:-/}"
GITHUB_REPO="${5:-openmind-walter/dummy-fe}"
GITHUB_BRANCH="${6:-dev}"

if [ -z "$APP_ID" ]; then
  echo "Usage: $0 <app_id> [component_name] [domain_name] [source_dir] [github_repo] [github_branch]"
  echo ""
  echo "Get app_id from: terraform output parent_app_id"
  exit 1
fi

# Get DigitalOcean API token
if [ -z "$DO_TOKEN" ]; then
  echo "Error: DO_TOKEN environment variable not set"
  echo "Set it with: export DO_TOKEN=your_token"
  exit 1
fi

echo "Fetching current app..."
APP_DATA=$(doctl apps get "$APP_ID" -o json)
CURRENT_SPEC=$(echo "$APP_DATA" | jq '.[0].spec')

echo "Adding component: $COMPONENT_NAME"
echo "Domain: $DOMAIN_NAME"
echo "Source Dir: $SOURCE_DIR"

# DigitalOcean App Platform API expects components in the spec
# Create the component structure
COMPONENT_JSON=$(jq -n \
  --arg name "$COMPONENT_NAME" \
  --arg domain "$DOMAIN_NAME" \
  --arg source_dir "$SOURCE_DIR" \
  --arg repo "$GITHUB_REPO" \
  --arg branch "$GITHUB_BRANCH" '{
    name: $name,
    type: "static_site",
    source_dir: $source_dir,
    github: {
      repo: $repo,
      branch: $branch,
      deploy_on_push: true
    },
    routes: [{
      path: "/"
    }],
    domains: [{
      domain: $domain,
      type: "PRIMARY"
    }]
  }')

# Merge with existing spec, adding components array if it doesn't exist
UPDATED_SPEC=$(echo "$CURRENT_SPEC" | jq --argjson component "$COMPONENT_JSON" '
  . + {
    components: ((.components // []) + [$component])
  }
')

echo ""
echo "Updated spec:"
echo "$UPDATED_SPEC" | jq '.'

echo ""
read -p "Do you want to update the app with this spec? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

echo "Updating app spec..."
# Create YAML spec file (DigitalOcean prefers YAML for app specs)
# Use macOS-compatible mktemp syntax
TEMP_SPEC=$(mktemp -t doctl-spec-XXXXXX).yaml

# Convert JSON to YAML format
echo "$UPDATED_SPEC" | yq eval -P - > "$TEMP_SPEC"

echo ""
echo "Spec file created at: $TEMP_SPEC"
echo "Preview:"
cat "$TEMP_SPEC"
echo ""

# Validate the spec first
if doctl apps spec validate "$TEMP_SPEC" 2>/dev/null; then
  echo "Spec is valid. Updating app..."
  doctl apps update "$APP_ID" --spec "$TEMP_SPEC"
else
  echo "Warning: Spec validation failed, but attempting update anyway..."
  doctl apps update "$APP_ID" --spec "$TEMP_SPEC"
fi

rm -f "$TEMP_SPEC"

echo ""
echo "⚠️  IMPORTANT: If you see 'unknown field components' error above,"
echo "   the DigitalOcean API/doctl has limitations with component updates."
echo ""
echo "   ✅ RECOMMENDED: Use the web console instead:"
echo "   https://cloud.digitalocean.com/apps/$APP_ID/settings"
echo ""
echo "   1. Click 'Edit Spec'"
echo "   2. Copy the spec shown above (from 'Preview:' section)"
echo "   3. Paste it and save"
echo ""
echo "   The web console is the most reliable method for adding components."
echo ""
echo "Once the component is deployed via web console, run: terraform apply"

