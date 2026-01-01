# --- 2. DigitalOcean Spaces Bucket Creation (Single Resource) ---
resource "digitalocean_spaces_bucket" "main_bucket" {
  name     = "${var.domain_prefix}${local.domain}"
  region   = var.do_space_region
  acl      = "public-read" 
}

# --- 2a. Create Static Site Folders and Index Files in Spaces ---
# This creates a separate folder and index.html file in Spaces for EACH static site
# Using for_each ensures one folder is created per site configuration
resource "null_resource" "create_spaces_folders" {
  for_each = var.site_configs

    triggers = {
      bucket_name    = digitalocean_spaces_bucket.main_bucket.name
      # Each site gets its own unique folder path (no trailing slash)
      spaces_path    = "${var.domain_prefix}${replace(each.key, "_", "-")}"
      site_key       = each.key  # Track which site this folder belongs to
      site_configs   = jsonencode(var.site_configs)
    }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      BUCKET_NAME="${digitalocean_spaces_bucket.main_bucket.name}"
      SPACES_REGION="${var.do_space_region}"
      # Each site gets its own folder: e.g., "dev-mobile-openmindsolutions-sg" or "dev-mobile-demokit-com"
      SPACES_PATH="${var.domain_prefix}${replace(each.key, "_", "-")}"
      SITE_NAME="${each.key}"
      SPACES_ACCESS_KEY="${var.spaces_access_id}"
      SPACES_SECRET_KEY="${var.spaces_secret_key}"
      
      if [ -z "$SPACES_ACCESS_KEY" ] || [ -z "$SPACES_SECRET_KEY" ]; then
        echo "Warning: Spaces credentials not set. Skipping folder creation for site: $SITE_NAME"
        exit 0
      fi
      
      echo "📁 Creating folder and index.html for site: $SITE_NAME"
      echo "   Path: s3://$BUCKET_NAME/$SPACES_PATH"
      
      # Create a temporary index.html file with site-specific content
      TEMP_INDEX=$(mktemp)
      echo "Spaces path: s3://$BUCKET_NAME/$SPACES_PATH" > "$TEMP_INDEX"
      
      # Upload index.html to Spaces using AWS CLI (S3-compatible)
      # Configure AWS CLI for DigitalOcean Spaces
      export AWS_ACCESS_KEY_ID="$SPACES_ACCESS_KEY"
      export AWS_SECRET_ACCESS_KEY="$SPACES_SECRET_KEY"
      export AWS_DEFAULT_REGION="$SPACES_REGION"
      
      # Upload the index.html file to this site's specific folder (add / for the file path)
      aws s3 cp "$TEMP_INDEX" "s3://$BUCKET_NAME/$SPACES_PATH/index.html" \
        --endpoint-url "https://$SPACES_REGION.digitaloceanspaces.com" \
        --acl public-read || {
        echo "⚠️  Warning: Failed to upload index.html for site $SITE_NAME"
        echo "   AWS CLI may not be installed. Install with:"
        echo "   macOS: brew install awscli"
        echo "   Linux: apt-get install awscli"
        exit 0  # Don't fail terraform, just warn
      }
      
      # Clean up
      rm -f "$TEMP_INDEX"
      
      echo "✅ Created index.html for site '$SITE_NAME' at s3://$BUCKET_NAME/$SPACES_PATH/index.html"
    EOT
  }

  depends_on = [digitalocean_spaces_bucket.main_bucket]
}