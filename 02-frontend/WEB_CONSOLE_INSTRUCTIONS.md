# Add Component via Web Console (Recommended)

The DigitalOcean API/doctl has issues with the "components" field structure. **Use the web console instead** - it's 100% reliable.

## Step-by-Step Instructions

### 1. Open Your App
Go to: https://cloud.digitalocean.com/apps/7cb1abfb-d3b7-4ce4-b5ed-817ae636d25d

### 2. Edit the Spec
- Click the **"Settings"** tab
- Scroll down to find **"App Spec"** section
- Click **"Edit Spec"** button

### 3. Replace the Entire Spec
Delete everything and paste this:

```yaml
name: sb
region: syd1

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

### 4. Save and Deploy
- Click **"Save Changes"**
- The app will automatically start deploying
- Wait 2-5 minutes for deployment to complete

### 5. Verify Deployment
- Go back to the app overview
- Check that you see a **"Live URL"** (e.g., `sb-xxxxx.ondigitalocean.app`)
- The component should show as **"Active"**

### 6. Create DNS Records
Once deployment is complete, run:

```bash
cd /Users/uqapp/sb-betting/do-setup/02-frontend
terraform apply
```

This will automatically create the CNAME record pointing `dev-mobile.openmindsolutions.sg` to your app's live URL.

## Why Use Web Console?

- ✅ **100% reliable** - No API limitations
- ✅ **Visual feedback** - See the spec structure clearly
- ✅ **Error messages** - Better error handling
- ✅ **No version issues** - Works regardless of doctl version

## Troubleshooting

**Can't find "Edit Spec" button?**
- Make sure you're in the **Settings** tab
- Look for "App Spec" or "Configuration" section
- Some UI versions have it under "Components" → "Edit"

**Spec validation errors?**
- Check YAML indentation (use 2 spaces, not tabs)
- Make sure `region: syd1` matches your Terraform config
- Verify the GitHub repo and branch exist

**Deployment fails?**
- Check the "Activity" tab for error messages
- Verify GitHub repo access permissions
- Ensure the branch exists in the repository

