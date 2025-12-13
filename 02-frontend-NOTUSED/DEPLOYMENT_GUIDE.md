# Deployment Guide for DigitalOcean App Platform

## Overview

This guide explains how to deploy your frontend application and configure custom domains for the DigitalOcean App Platform.

## Current Setup

- **App Name**: `sb` (from `var.app_name`)
- **Region**: `syd1` (from `do_space_region`)
- **Spaces Bucket**: `dev-sb` (for storing static assets)
- **Site Configuration**: `dev-mobile.openmindsolutions.sg`

## Deployment Workflow

### Step 1: Build Your Frontend Application

Build your Angular/React/static site application:

```bash
# Example for Angular
ng build --configuration=production --output-path=./dist/dev-mobile_openmindsolutions_sg

# Example for React
npm run build
# Then copy to: ./dist/dev-mobile_openmindsolutions_sg
```

Your build output should be in: `dev-mobile_openmindsolutions_sg/dist/`

### Step 2: Upload to DigitalOcean Spaces (Optional)

If you want to use Spaces as a CDN for your assets:

```bash
# Install doctl if not already installed
# brew install doctl (on macOS)

# Configure Spaces credentials
export SPACES_ACCESS_KEY_ID="your_spaces_access_key"
export SPACES_SECRET_ACCESS_KEY="your_spaces_secret_key"

# Upload to Spaces
doctl spaces s3 sync ./dist/dev-mobile_openmindsolutions_sg \
  s3://dev-sb/dev-mobile_openmindsolutions_sg/dist \
  --region syd1
```

### Step 3: Add Static Site Component to App Platform

Since Terraform doesn't support dynamic components, you need to add the component manually:

#### Option A: Via DigitalOcean Console

1. Go to [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
2. Click on your app (`sb`)
3. Click **"Settings"** → **"Components"**
4. Click **"Edit Spec"** or **"Add Component"**
5. Add a static site component:

```yaml
components:
  - name: mobile_openmindsolutions_sg
    type: static_site
    source_dir: /
    github:
      repo: openmind-walter/dummy-fe
      branch: dev
      deploy_on_push: true
    routes:
      - path: /
    domains:
      - domain: dev-mobile.openmindsolutions.sg
        type: PRIMARY
```

6. Save and deploy

#### Option B: Via DigitalOcean API

Use the script provided below or the `doctl` CLI:

```bash
# Get your app ID from Terraform output
terraform output parent_app_id

# Update app spec via API (see deploy-component.sh script)
```

### Step 4: Configure Custom Domain

Once the component is deployed and the app has a `live_url`:

1. The app will automatically get a `live_url` (e.g., `sb-xxxxx.ondigitalocean.app`)
2. Run Terraform again to create DNS records:
   ```bash
   terraform apply
   ```
3. Terraform will create the CNAME record: `dev-mobile.openmindsolutions.sg` → `sb-xxxxx.ondigitalocean.app`

## Configuration Details

Based on your `dev.frontend.tfvars`:

```hcl
mobile_openmindsolutions_sg = {
  domain_name   = "dev-mobile.openmindsolutions.sg"  # Custom domain
  dns_zone      = "openmindsolutions.sg"              # DNS zone
  bucket_name   = "dev-sb"                           # Spaces bucket
  source_dir    = "dev-mobile_openmindsolutions_sg/dist"  # Build output path
}
```

## Troubleshooting

### "Domains: You will be able to configure custom domains once you have successfully deployed your app"

This message appears because:
1. The app has no components deployed yet
2. No `live_url` is available until components are deployed

**Solution**: Add a static site component (Step 3 above), then the domain configuration will be available.

### DNS Records Not Created

If DNS records aren't created automatically:
- Check that `terraform output app_cname_target` shows a valid URL
- Verify the app has a `live_url` (check in DigitalOcean console)
- Run `terraform apply` again after the component is deployed

## Next Steps

1. Build your frontend application
2. Add the static site component to your app (via console or API)
3. Wait for deployment to complete
4. Run `terraform apply` to create DNS records
5. Verify DNS propagation (may take a few minutes)

