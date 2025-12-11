# main.tf

# --- Providers Configuration ---
# Note: Provider configuration is in the parent module (00-Env)
# terraform {
#   required_providers {
#     digitalocean = {
#       source  = "digitalocean/digitalocean"
#       version = "~> 2.36.0"
#     }
#     null = {
#       source  = "hashicorp/null"
#       version = "~> 3.0"
#     }
#   }
# }

# --- 1. Base App Platform Application Creation ---
# Creates the parent App Platform application with a minimal spec.
# resource "digitalocean_app" "parent_app" {
#   spec {
#     name   = "${var.domain_prefix}${var.app_name}"
#     region = var.do_space_region 
#   }
# }

# --- 2. DigitalOcean Spaces Bucket Creation ---
# Creates a unique Spaces bucket for each site configuration.
# resource "digitalocean_spaces_bucket" "sites" {
#   for_each = var.site_configs
#   name     = each.value.bucket_name
#   region   = var.do_space_region
#   acl      = "public-read" # Allows the assets to be publicly served
# }

# Creates a single Spaces bucket named by the 'main_bucket_name' variable.
resource "digitalocean_spaces_bucket" "main_bucket" {
  name     = "${var.domain_prefix}${var.app_name}"
  region   = var.do_space_region
  acl      = "public-read" 
}

# --- 3. DNS Zone Reference ---
# References existing DNS zones (domains must already exist in DigitalOcean)
# Use distinct() to ensure we only reference the zone once for shared domains
data "digitalocean_domain" "zone" {
  for_each = toset(values(var.site_configs)[*].dns_zone)
  name     = each.key
}

# --- 4. Add/Update Static Site Components and Routing ---
# # This resource takes the base app's spec and ADDS the necessary static_site components.
# resource "digitalocean_app" "multi_site_components" {
#   # Reference the ID of the parent app
#   app_id = digitalocean_app.parent_app.id 
  
#   # Base the new spec on the parent app's spec
#   spec = digitalocean_app.parent_app.spec
  
#   dynamic "static_site" {
#     for_each = var.site_configs
    
#     content {
#       # Component Name: Use the unique map key (e.g., 'site_a')
#       name = static_site.key

#       # Placeholder Git source is required even if the actual content is synced from Spaces
#       # during a CI/CD build step.
#       git {
#         repo           = "openmind-walter/dummy-fe"
#         branch         = var.env
#         deploy_on_push = true
#       }
#       # ng build --prod --output-path=./dist/<site_a>
#       # # Example to sync Angular build to your Space
#       #doctl spaces s3 sync ./dist/site_a s3://${BUCKET_NAME}/site_a/dist --region ${SPACES_REGION}

#       # The source_dir is the path *inside* the component where the synced files will be.
#       source_dir = static_site.value.source_dir 

#       index_document = "index.html" 
      
#       # Route the custom domain to this specific component
#       custom_domains = [static_site.value.domain_name]
      
#       # Optional: Add environment variables for the build phase to facilitate Space sync
#       # env {
#       #   key = "SPACES_BUCKET"
#       #   value = static_site.value.bucket_name
#       # }
#       # build_command = "doctl s3 sync s3://${var.main_bucket_name}${static_site.value.source_dir} ."
#     }
#   }
# }
# 1. Base App Platform Application Creation and Component Definition
# Create the app first, then add components via REST API (bypassing doctl limitations)
resource "digitalocean_app" "parent_app" {
  spec {
    name   = "${var.env}-${var.app_name}"
    region = var.do_space_region
  }
}

# Data source to get fresh app data after components are added
# This ensures we have the latest live_url
data "digitalocean_app" "parent_app_refresh" {
  app_id = digitalocean_app.parent_app.id
  
  depends_on = [null_resource.add_components]
}

# 2. Add components to the app using REST API (fully automated)
# This attempts to bypass doctl limitations, but may fall back to manual steps
# if the API has restrictions
resource "null_resource" "add_components" {
  count = length(var.site_configs) > 0 ? 1 : 0

  triggers = {
    app_id         = digitalocean_app.parent_app.id
    site_configs   = jsonencode(var.site_configs)
    app_name       = var.app_name
    region         = var.do_space_region
    github_repo    = var.github_repo
    github_branch  = var.github_branch
  }

  # Continue even if component addition fails (allows manual fallback)
  lifecycle {
    ignore_changes = [triggers]
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      APP_ID="${digitalocean_app.parent_app.id}"
      # Get DO_TOKEN from environment variable (set by Terraform provider)
      DO_TOKEN="${var.do_token}"
      
      if [ -z "$DO_TOKEN" ]; then
        echo "Error: DO_TOKEN not set. Please ensure do_token is set in terraform.tfvars"
        exit 1
      fi
      
      echo "Fetching current app spec for app $APP_ID..."
      
      # Fetch current app data
      APP_DATA=$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        "https://api.digitalocean.com/v2/apps/$APP_ID")
      
      # Extract current spec or create base spec
      CURRENT_SPEC=$(echo "$APP_DATA" | jq -r '.app.spec // empty')
      
      if [ -z "$CURRENT_SPEC" ] || [ "$CURRENT_SPEC" = "null" ]; then
        echo "No existing spec found, creating base spec..."
        CURRENT_SPEC=$(jq -n \
          --arg name "${var.app_name}" \
          --arg region "${var.do_space_region}" \
          '{name: $name, region: $region}')
      else
        echo "Found existing spec, will merge components..."
      fi
      
      # Build static_sites array from site_configs
      # Note: App Platform API uses "static_sites" not "components"
      # Names must use hyphens, not underscores (convert .key)
      echo "Building static_sites from site_configs..."
      STATIC_SITES=$(jq -n \
        --argjson site_configs '${jsonencode(var.site_configs)}' \
        --arg repo "${var.github_repo}" \
        --arg branch "${var.github_branch}" \
        '[$site_configs | to_entries[] | {
          # Convert underscores to hyphens for name validation
          name: (.key | gsub("_"; "-")),
          # Use the source_dir from config - this is where the built files are
          source_dir: .value.source_dir,
          github: {
            repo: $repo,
            branch: $branch,
            deploy_on_push: true
          },
          routes: [{path: "/"}]
          # Domains are configured via DNS records (Terraform), not in the spec
          # Each static_site will serve content from its source_dir
          # DNS routing will direct traffic to the app, and App Platform will serve the appropriate content
        }]')
      
      # Merge static_sites into spec (preserve existing static_sites if any)
      UPDATED_SPEC=$(echo "$CURRENT_SPEC" | jq --argjson static_sites "$STATIC_SITES" '
        . + {
          static_sites: ((.static_sites // []) + $static_sites)
        }
      ')
      
      echo "Updated spec with components:"
      echo "$UPDATED_SPEC" | jq '.'
      
      # Update app via REST API - DigitalOcean API v2 format
      # The API requires the spec to be wrapped in a "spec" field in the request
      echo "Updating app via REST API..."
      # Use temporary files to avoid shell escaping issues
      TEMP_SPEC=$(mktemp)
      TEMP_RESPONSE=$(mktemp)
      
      # Wrap spec in proper request structure: { "spec": {...} }
      REQUEST_BODY=$(echo "$UPDATED_SPEC" | jq -c '{spec: .}')
      echo "$REQUEST_BODY" > "$TEMP_SPEC"
      
      echo "Request body:"
      cat "$TEMP_SPEC" | jq '.'
      
      # Escape % for Terraform heredoc: use %% to get %
      HTTP_CODE=$(curl -s -w "%%{http_code}" -o "$TEMP_RESPONSE" -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $DO_TOKEN" \
        -d @"$TEMP_SPEC" \
        "https://api.digitalocean.com/v2/apps/$APP_ID")
      
      BODY=$(cat "$TEMP_RESPONSE")
      rm -f "$TEMP_SPEC" "$TEMP_RESPONSE"
      
      if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
        echo "✅ Successfully added components to app $APP_ID"
        echo "Response:"
        echo "$BODY" | jq '.' || echo "$BODY"
        echo ""
        echo "App is now deploying. Waiting for live_url to be available..."
        
        # Wait for the app to have a live_url (poll every 10 seconds, max 10 minutes)
        MAX_WAIT=600  # 10 minutes
        WAIT_INTERVAL=10
        ELAPSED=0
        LIVE_URL=""
        
        while [ $ELAPSED -lt $MAX_WAIT ]; do
          APP_DATA=$(curl -s -X GET \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $DO_TOKEN" \
            "https://api.digitalocean.com/v2/apps/$APP_ID")
          
          LIVE_URL=$(echo "$APP_DATA" | jq -r '.app.live_url // empty')
          
          # Also check deployment status
          ACTIVE_DEPLOYMENT=$(echo "$APP_DATA" | jq -r '.app.active_deployment.id // empty')
          DEPLOYMENT_PHASE=$(echo "$APP_DATA" | jq -r '.app.active_deployment.phase // empty')
          
          if [ -n "$LIVE_URL" ] && [ "$LIVE_URL" != "null" ] && [ "$LIVE_URL" != "" ]; then
            echo "✅ App now has live_url: $LIVE_URL"
            break
          fi
          
          if [ -n "$ACTIVE_DEPLOYMENT" ] && [ "$ACTIVE_DEPLOYMENT" != "null" ]; then
            echo "Waiting for live_url... ($${ELAPSED}s/$${MAX_WAIT}s) - Deployment phase: $${DEPLOYMENT_PHASE}"
          else
            echo "Waiting for live_url... ($${ELAPSED}s/$${MAX_WAIT}s) - No active deployment yet"
          fi
          
          sleep $$WAIT_INTERVAL
          ELAPSED=$$((ELAPSED + WAIT_INTERVAL))
        done
        
        if [ -z "$LIVE_URL" ] || [ "$LIVE_URL" = "null" ] || [ "$LIVE_URL" = "" ]; then
          echo "⚠️  Warning: App did not get a live_url within $${MAX_WAIT} seconds"
          echo "The app may still be deploying. DNS records will be created on the next terraform apply."
        else
          echo "✅ App is ready with live_url: $LIVE_URL"
        fi
      else
        echo "⚠️  Warning: API update failed with HTTP $HTTP_CODE"
        echo "Response body:"
        echo "$BODY" | jq '.' || echo "$BODY"
        echo ""
        echo "The DigitalOcean API has limitations with component updates."
        echo "Please add components manually via the web console:"
        echo "https://cloud.digitalocean.com/apps/$APP_ID/settings"
        echo ""
          echo "Use this spec (convert to YAML format):"
          echo "$UPDATED_SPEC" | yq eval -P - 2>/dev/null || {
            echo "# YAML format:"
            echo "name: ${var.app_name}"
            echo "region: ${var.do_space_region}"
            echo ""
            echo "static_sites:"
            for key in $(echo "$UPDATED_SPEC" | jq -r '.static_sites[]?.name // empty'); do
              echo "  - name: $key"
              echo "    source_dir: /"
              echo "    github:"
              echo "      repo: ${var.github_repo}"
              echo "      branch: ${var.github_branch}"
              echo "      deploy_on_push: true"
              echo "    routes:"
              echo "      - path: /"
            done
          }
        echo ""
        echo "⚠️  Continuing Terraform execution - DNS records will be created"
        echo "   once you manually add components and the app has a live_url."
        # Don't exit with error - allow Terraform to continue
        # The DNS records will be created automatically once components are added
      fi
    EOT
    
    # DO_TOKEN should be available from the provider or environment
  }

  depends_on = [digitalocean_app.parent_app]
  
  # Wait a bit for the app to be ready before adding components
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Components will be removed when app is destroyed'"
  }
}

# --- 5. Create the CNAME Record for DNS Routing ---
# Local variables to safely extract values from the App Platform deployment
locals {
  # The live_url (CNAME target) is only known AFTER the App Platform deployment starts
  # Use the data source to get fresh app data after components are added
  app_cname_alias = try(
    data.digitalocean_app.parent_app_refresh.live_url,
    digitalocean_app.parent_app.live_url,
    ""
  )
  
  # Calculate DNS record names for each site
  # Extract subdomain by splitting on the dns_zone and taking the first part
  dns_record_names = {
    for key, config in var.site_configs : key => (
      config.domain_name == config.dns_zone ? "@" : (
        # Split by the dns_zone (with dot prefix) and take the first element
        # Example: "dev-mobile.openmindsolutions.sg" split by ".openmindsolutions.sg" = ["dev-mobile", ""]
        # Then take the first element and trim any trailing dots
        trimsuffix(split(".${config.dns_zone}", config.domain_name)[0], ".")
      )
    )
  }
}

# Create DNS records for each site configuration
# Note: Records will only be created if app has a live_url (handled via validation)
resource "digitalocean_record" "cname_app_routing" {
  for_each = var.site_configs
  
  # The DNS zone to attach the record to (e.g., mysite.com)
  domain = each.value.dns_zone 
  type   = "CNAME"
  
  # Use the pre-calculated name from locals
  # This ensures the name is never empty and is calculated correctly
  name = local.dns_record_names[each.key]

  # The target provided by the App Platform
  # CNAME values must end with a dot (.) per DNS standards
  # If live_url is not available yet, use a placeholder that will be updated on next apply
  # Note: Using a placeholder - this will cause DNS resolution to fail until live_url is available
  # This is intentional - the record will be updated automatically on the next terraform apply
  value = (
    local.app_cname_alias != null && local.app_cname_alias != "" && local.app_cname_alias != "." ?
    "${trimsuffix(trimsuffix(local.app_cname_alias, "/"), ".")}." :
    "placeholder.ondigitalocean.app."
  )
  ttl   = 300
  
  # Ensure the CNAME is created only after the App Platform has been deployed
  depends_on = [digitalocean_app.parent_app, null_resource.add_components]
  
  # Validate that required values are available
  lifecycle {
    precondition {
      condition     = local.dns_record_names[each.key] != null && local.dns_record_names[each.key] != ""
      error_message = "DNS record name cannot be empty for ${each.key}. Domain: ${each.value.domain_name}, DNS Zone: ${each.value.dns_zone}"
    }
    # Use postcondition instead of precondition to allow creation but warn if live_url is missing
    # This allows DNS records to be created in a second apply once the app is ready
    postcondition {
      condition     = local.app_cname_alias != null && local.app_cname_alias != "" && local.app_cname_alias != "."
      error_message = "⚠️  WARNING: App Platform app does not have a live_url yet. The DNS record was created but may not work until the app is fully deployed. Current value: '${local.app_cname_alias}'. Run 'terraform apply' again once the app has a live_url, or check the app status in the DigitalOcean console."
    }
  }
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

# output "spaces_endpoints" {
#   description = "The endpoints for the created DigitalOcean Spaces."
#   value       = { for k, v in digitalocean_spaces_bucket.sites : k => v.bucket_domain_name }
# }

output "deployed_domains" {
  description = "The domains configured in App Platform and DNS."
  value       = [for site in var.site_configs : site.domain_name]
}

output "dns_record_names_debug" {
  description = "Debug: Calculated DNS record names for each site."
  value       = local.dns_record_names
}