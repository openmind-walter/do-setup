# main.tf


locals {
  # 1. Define the list of static site component configurations based on site_configs
  # Convert underscores to hyphens in names (App Platform requirement: ^[a-z][a-z0-9-]{0,30}[a-z0-9]$)
  static_site_configs = [for k, v in var.site_configs : {
    name           = replace(k, "_", "-")  # Convert underscores to hyphens
    # Source from Spaces instead of GitHub
    spaces_bucket  = digitalocean_spaces_bucket.main_bucket.name
    spaces_region  = var.do_space_region
    # Path in Spaces bucket - based on your URL: dev-mobile_openmindsolutions_sg/index.html
    # So the path should be: dev-mobile_openmindsolutions_sg/
    spaces_path    = "${k}/"  # Path in Spaces bucket (e.g., "dev-mobile_openmindsolutions_sg/")
    source_dir     = "/"  # Files will be synced to root during build
    domain_name    = v.domain_name
    index_document = "index.html"
  }]

  # 2. Extract the hostname from live_url for CNAME records
  #    Remove protocol (https://) and trailing slash, then add trailing dot for DNS
  app_cname_alias = (
    digitalocean_app.parent_app.live_url != null && digitalocean_app.parent_app.live_url != "" ?
    "${trimsuffix(trimprefix(trimprefix(digitalocean_app.parent_app.live_url, "https://"), "http://"), "/")}." :
    ""
  )
}

# --- 2. DigitalOcean Spaces Bucket Creation (Single Resource) ---
resource "digitalocean_spaces_bucket" "main_bucket" {
  name     = "${var.domain_prefix}${var.app_name}"
  region   = var.do_space_region
  acl      = "public-read" 
}

# --- 3. DNS Zone Reference ---
# References existing DNS zones (domains must already exist in DigitalOcean)
data "digitalocean_domain" "zone" {
  for_each = toset(values(var.site_configs)[*].dns_zone)
  name     = each.key
}

# --- 4. Check GitHub Connection (Pre-flight check) ---
# This checks if GitHub is connected before attempting to create the app
resource "null_resource" "check_github_connection" {
  # Only run if we have site_configs that use GitHub
  count = length(var.site_configs) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      DO_TOKEN="${var.do_token}"
      if [ -z "$DO_TOKEN" ]; then
        echo "Error: DO_TOKEN not set"
        exit 1
      fi
      
      echo "Checking GitHub connection to DigitalOcean..."
      
      # Try to get integrations (this endpoint may not exist, so we'll handle errors gracefully)
      INTEGRATIONS=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/integrations" 2>/dev/null || echo "{}")
      
      GITHUB_CONNECTED=$(echo "$INTEGRATIONS" | jq -r '.integrations[]? | select(.provider == "github") | .provider // empty' 2>/dev/null || echo "")
      
      if [ -z "$GITHUB_CONNECTED" ]; then
        echo ""
        echo "⚠️  WARNING: GitHub may not be connected to DigitalOcean"
        echo ""
        echo "If you get 'GitHub user not authenticated' error, connect GitHub:"
        echo "1. Go to: https://cloud.digitalocean.com/account/api/integrations"
        echo "2. Click 'Connect GitHub' and authorize access"
        echo "3. Grant access to repository: ${var.github_repo}"
        echo ""
        echo "Continuing anyway - Terraform will show a clearer error if GitHub is not connected..."
      else
        GITHUB_ACCOUNT=$(echo "$INTEGRATIONS" | jq -r '.integrations[]? | select(.provider == "github") | .account_name // "Unknown"' 2>/dev/null || echo "Unknown")
        echo "✅ GitHub is connected (Account: $GITHUB_ACCOUNT)"
      fi
    EOT
  }

  # Continue even if check fails - the actual error will be clearer from the app resource
  lifecycle {
    ignore_changes = [triggers]
  }
}

# --- 5. Single App Platform Resource (Creation and Component Definition) ---
# This resource manages the entire application and all its components.
resource "digitalocean_app" "parent_app" {
  depends_on = [null_resource.check_github_connection]
  
  spec {
    name   = "${var.domain_prefix}${var.app_name}"
    region = var.do_space_region

    # Loop over the site_configs to define all static_site components
    dynamic "static_site" {
      for_each = local.static_site_configs
      
      content {
        # The key is used as the unique component name (e.g., 'site_a')
        name = static_site.value.name 

        # Use a minimal GitHub source (required by App Platform, but we'll sync from Spaces)
        # You can use any public repo or create a minimal one with just a README
        github {
          repo           = var.github_repo
          branch         = var.github_branch
          deploy_on_push = false  # We're syncing from Spaces, not using GitHub files
        }
        
        source_dir     = static_site.value.source_dir 
        index_document = static_site.value.index_document 
        
        # Build command: Sync files from DigitalOcean Spaces
        # The files are already built and stored in Spaces at:
        # https://${static_site.value.spaces_bucket}.${static_site.value.spaces_region}.digitaloceanspaces.com/${static_site.value.spaces_path}
        build_command = <<-EOT
          # Install AWS CLI (for S3-compatible Spaces API)
          # apt-get update && apt-get install -y awscli || yum install -y aws-cli || apk add --no-cache aws-cli
          
          # Configure AWS CLI for DigitalOcean Spaces
          aws configure set aws_access_key_id $${SPACES_ACCESS_KEY_ID}
          aws configure set aws_secret_access_key $${SPACES_SECRET_ACCESS_KEY}
          aws configure set default.region ${static_site.value.spaces_region}
          
          # Sync files from Spaces to the output directory
          aws s3 sync s3://${static_site.value.spaces_bucket}/${static_site.value.spaces_path} . \
            --endpoint-url https://${static_site.value.spaces_region}.digitaloceanspaces.com \
            --delete
        EOT
        
        # Environment variables for Spaces access (will be set from provider)
        env {
          key   = "SPACES_ACCESS_KEY_ID"
          value = var.spaces_access_id
          scope = "BUILD_TIME"
        }
        
        env {
          key   = "SPACES_SECRET_ACCESS_KEY"
          value = var.spaces_secret_key
          scope = "BUILD_TIME"
        }
        
        # Note: Domains are configured at the app level (above)
        # DNS records (CNAME) are also created below in digitalocean_record.cname_app_routing
        # Routes are automatically configured for static sites at "/"
      }
    }
  }
}

# --- 5. Add Custom Domains to App Platform via API ---
# The Terraform provider doesn't support domains configuration directly,
# so we use the REST API to add domains after the app is created
resource "null_resource" "add_domains" {
  count = length(var.site_configs) > 0 ? 1 : 0

  triggers = {
    app_id       = digitalocean_app.parent_app.id
    site_configs = jsonencode(var.site_configs)
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      APP_ID="${digitalocean_app.parent_app.id}"
      DO_TOKEN="${var.do_token}"
      
      if [ -z "$DO_TOKEN" ]; then
        echo "Error: DO_TOKEN not set"
        exit 1
      fi
      
      echo "Adding custom domains to app $APP_ID..."
      
      # Use temporary files to avoid shell variable issues with control characters
      TEMP_APP_DATA=$(mktemp)
      TEMP_SPEC=$(mktemp)
      
      # Get current app spec
      curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps/$APP_ID" > "$TEMP_APP_DATA"
      
      # Extract spec - handle it as JSON value (could be object or JSON-encoded string)
      # Check if spec is a string type
      SPEC_TYPE=$(jq -r 'type(.app.spec)' "$TEMP_APP_DATA" 2>/dev/null || echo "null")
      
      if [ "$SPEC_TYPE" = "string" ]; then
        # Spec is a JSON-encoded string, parse it
        jq -r '.app.spec | fromjson' "$TEMP_APP_DATA" > "$TEMP_SPEC" 2>/dev/null || echo "{}" > "$TEMP_SPEC"
      elif [ "$SPEC_TYPE" = "object" ] || [ "$SPEC_TYPE" = "null" ]; then
        # Spec is already an object (or null)
        jq -c '.app.spec // {}' "$TEMP_APP_DATA" > "$TEMP_SPEC" 2>/dev/null || echo "{}" > "$TEMP_SPEC"
      else
        # Fallback: create empty spec
        echo "{}" > "$TEMP_SPEC"
      fi
      
      # Ensure we have valid JSON object (not null)
      if ! jq -e 'type == "object"' "$TEMP_SPEC" >/dev/null 2>&1; then
        echo "Warning: Spec is not a valid object, using empty spec"
        echo "{}" > "$TEMP_SPEC"
      fi
      
      # Build domains array from site_configs
      DOMAINS=$(jq -n \
        --argjson site_configs '${jsonencode(var.site_configs)}' \
        '[.site_configs | to_entries[] | {
          domain: .value.domain_name,
          type: "PRIMARY"
        }]')
      
      # Merge domains into spec - ensure we're working with an object
      jq --argjson domains "$DOMAINS" '
        (if . == null then {} else . end) + {
          domains: ((.domains // []) + $domains | unique_by(.domain))
        }
      ' "$TEMP_SPEC" > "$TEMP_SPEC.merged"
      
      # Move merged spec back
      mv "$TEMP_SPEC.merged" "$TEMP_SPEC"
      
      # Update app spec - use the merged spec from temp file
      TEMP_REQUEST=$(mktemp)
      jq -c '{spec: .}' "$TEMP_SPEC" > "$TEMP_REQUEST"
      
      HTTP_CODE=$(curl -s -w "%%{http_code}" -o /dev/null -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        -d @"$TEMP_REQUEST" \
        "https://api.digitalocean.com/v2/apps/$APP_ID")
      
      # Clean up temporary files
      rm -f "$TEMP_APP_DATA" "$TEMP_SPEC" "$TEMP_REQUEST"
      
      if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
        echo "✅ Successfully added domains to app"
      else
        echo "⚠️  Warning: Failed to add domains (HTTP $HTTP_CODE)"
        echo "You may need to add domains manually via the web console"
      fi
    EOT
  }

  depends_on = [digitalocean_app.parent_app]
}

# --- 6. Create the CNAME Record for DNS Routing ---
# --- 6. CNAME records -------------------------------------------------
resource "digitalocean_record" "cname_app_routing" {
  for_each = var.site_configs

  # Ensure domains are added to app before creating DNS records
  depends_on = [null_resource.add_domains]

  domain = each.value.dns_zone
  type   = "CNAME"

  # Calculate DNS record name: extract subdomain from domain_name
  # Example: "dev-mobile.openmindsolutions.sg" with zone "openmindsolutions.sg" -> "dev-mobile"
  name = (
    each.value.domain_name == each.value.dns_zone ? "@" :
    trimsuffix(split(".${each.value.dns_zone}", each.value.domain_name)[0], ".")
  )

  # CNAME value must end with a dot (.) per DNS standards
  value = local.app_cname_alias != "" ? local.app_cname_alias : "placeholder.ondigitalocean.app."
  ttl   = 300
}

# --- OUTPUTS ---

output "parent_app_id" {
  description = "The DigitalOcean App Platform ID."
  value       = digitalocean_app.parent_app.id
}

output "app_cname_target" {
  description = "The CNAME target all custom domains should point to."
  value       = trimsuffix(local.app_cname_alias, "/")
}

output "spaces_endpoint" {
  description = "The endpoint for the single main DigitalOcean Space."
  value       = digitalocean_spaces_bucket.main_bucket.bucket_domain_name
}