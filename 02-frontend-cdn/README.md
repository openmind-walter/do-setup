# Cloudflare CDN Setup

This module configures Cloudflare zones, DNS records, Workers, and caching rules for static sites.

## Required Variables

You need to provide the following variables:

### 1. Cloudflare Account ID

Get your Account ID from:
- Go to https://dash.cloudflare.com/
- Click on your account in the right sidebar
- Copy the Account ID

Add to `dev.frontend-cdn.tfvars`:
```hcl
cloudflare_account_id = "your_account_id_here"
```

### 2. Cloudflare API Token

Create an API token with the following permissions. **See `API_TOKEN_SETUP.md` for detailed step-by-step instructions.**

**Account-level permissions** (for Workers):
- **Account** → **Workers Scripts** → **Edit**
- **Account** → **Workers Routes** → **Edit**

**Zone-level permissions** (for DNS, cache, rulesets):
- **Zone** → **Zone** → **Read**, **Edit**
- **Zone** → **Zone Settings** → **Read**, **Edit**
- **Zone** → **DNS** → **Read**, **Edit**
- **Zone** → **Cache Purge** → **Purge**
- **Zone** → **Transform Rules** → **Edit** ⚠️ **REQUIRED for rulesets**
- **Zone** → **Zone Rulesets** → **Edit** (alternative to Transform Rules)

**Important**: 
- Workers permissions are under **Account** (not Zone)
- For rulesets, you need **Transform Rules: Edit** (Zone level) - this is likely missing if you get "Authentication error (10000)"
- If you can't find a permission, it might be named slightly differently in the UI

Add to `dev.frontend-cdn.tfvars`:
```hcl
cloudflare_api_token = "your_api_token_here"
```

Or set as environment variable:
```bash
export TF_VAR_cloudflare_api_token="your_api_token_here"
```

## Optional: Auto-Create Zones

If you want Terraform to create Cloudflare zones automatically:

```hcl
create_zones = true
cloudflare_zone_plan = "free"  # or "pro", "business", "enterprise"
cloudflare_jump_start = false
```

**Important**: When creating zones:
1. You must own the domain
2. After zone creation, Cloudflare will provide nameservers
3. Update your domain registrar to use Cloudflare's nameservers
4. DNS propagation can take 24-48 hours

## Usage

```bash
cd 02-frontend-cdn
terraform init
terraform plan -var-file=../00-Env/dev.frontend-cdn.tfvars
terraform apply -var-file=../00-Env/dev.frontend-cdn.tfvars
```

## Resources Created

- Cloudflare zones (if `create_zones = true`)
- DNS CNAME records pointing to DigitalOcean Spaces
- Cloudflare Worker script for routing
- Worker routes for each domain
- Cache rules for static assets, HTML, and API bypass

