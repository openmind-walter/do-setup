# Cloudflare API Token Setup Guide

## Step-by-Step Instructions

### 1. Go to API Tokens
Navigate to: https://dash.cloudflare.com/profile/api-tokens
create a custom api with following permissions
'''
All accounts - Workers Scripts:Edit
All zones - Cache Rules:Edit, Transform Rules:Edit, Zone Settings:Edit, Zone:Edit, Workers Routes:Edit, Cache Purge:Purge, DNS:Edit
'''
### 2. Create Custom Token
Click **"Create Token"** → **"Create Custom Token"**

### 3. Set Token Name
Give it a descriptive name, e.g., "Terraform CDN Management"

### 4. Configure Permissions

#### Account Permissions (REQUIRED for Workers):
- **Account** → **Workers Scripts** → **Edit** ⚠️ **REQUIRED for Workers**
- **Account** → **Workers Routes** → **Edit** (optional, but recommended)

#### Zone Permissions (select your zones or "All zones"):
- **Zone** → **Zone** → **Read**, **Edit**
- **Zone** → **Zone Settings** → **Read**, **Edit**
- **Zone** → **DNS** → **Read**, **Edit**
- **Zone** → **Cache Purge** → **Purge**
- **Zone** → **Transform Rules** → **Edit** ⚠️ **REQUIRED for rulesets**
- **Zone** → **Zone Rulesets** → **Edit** (alternative to Transform Rules)

### 5. Zone Resources
- Select **"Include"** → **"All zones"** (or specific zones)
- Or select specific zones: `openmindsolutions.sg`, `sb-demokit.com`, etc.

### 6. Account Resources (if using Workers)
- Select **"Include"** → **"All accounts"** (or your specific account)

### 7. Create Token
Click **"Continue to summary"** → **"Create Token"**

### 8. Copy Token
**⚠️ IMPORTANT**: Copy the token immediately - you won't be able to see it again!

### 9. Add to Terraform
Add to `dev.frontend-cdn.tfvars`:
```hcl
cloudflare_api_token = "your_token_here"
```

Or set as environment variable:
```bash
export TF_VAR_cloudflare_api_token="your_token_here"
```

## Troubleshooting

### Error: "request is not authorized" or "Authentication error (10000)"
This means your token is missing the permission to create/edit **Zone Rulesets**.

**The exact permission you need:**
- **Zone** → **Zone Rulesets** → **Edit** (most common name)
- OR **Zone** → **Transform Rules** → **Edit** (alternative name)
- OR **Zone** → **Rules** → **Edit** (older name)
- OR **Zone** → **Page Rules** → **Edit** (legacy name)

**How to find it in the Cloudflare dashboard:**
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click **Edit** on your token
3. Scroll to **Zone Permissions**
4. Look for any of these options:
   - "Zone Rulesets" → "Edit"
   - "Transform Rules" → "Edit"
   - "Rules" → "Edit"
   - "Page Rules" → "Edit"
5. Select **Edit** permission
6. Make sure your zones are included in **Zone Resources** section
7. Save the token

**Important**: The permission name varies by account type and Cloudflare UI version. If you don't see any of these, try:
- **Zone Settings** → **Edit** (sometimes includes rulesets)
- Or contact Cloudflare support to enable rulesets API access

### Can't find "Workers Scripts" permission?
- **IMPORTANT**: This is an **Account-level** permission, NOT Zone-level
- Go to **Account Permissions** section (scroll up from Zone Permissions)
- Look for:
  - **"Workers Scripts"** → **"Edit"** (most common)
  - **"Workers"** → **"Scripts"** → **"Edit"**
  - **"Account"** → **"Workers Scripts"** → **"Edit"**
- Make sure **Account Resources** includes your account (or "All accounts")
- If you still can't find it, your account might need Workers enabled first

### Testing Your Token Permissions
You can test if your token has the right permissions by running:
```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/rulesets" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"
```

If you get a successful response (200), your token has rulesets access. If you get 403, you need to add the permission.

### Alternative: Use API Key (Not Recommended)
If you can't create a token with the right permissions, you can use the Global API Key:
```hcl
provider "cloudflare" {
  api_key = var.cloudflare_api_key
  email   = var.cloudflare_email
}
```
⚠️ **Warning**: Global API Key has full account access - less secure than tokens.

