# Manual Deployment Guide

**Note**: The DigitalOcean API/doctl currently has issues with the "components" field structure. The web console is the most reliable method.

## Option 1: Via DigitalOcean Web Console (Recommended - Most Reliable)

1. Go to https://cloud.digitalocean.com/apps
2. Click on your app: **sb** (ID: `7cb1abfb-d3b7-4ce4-b5ed-817ae636d25d`)
3. Click **"Settings"** tab
4. Scroll down and click **"Edit Spec"** button (or look for "App Spec" section)
5. You'll see the current spec. Replace it entirely with this YAML:

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

6. Click **"Save Changes"**
7. The app will automatically deploy

## Option 2: Using doctl with YAML file

1. Create a file `app-spec.yaml`:

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

2. Update the app:
```bash
doctl apps update 7cb1abfb-d3b7-4ce4-b5ed-817ae636d25d --spec app-spec.yaml
```

## After Deployment

Once the component is deployed:

1. The app will get a `live_url` (e.g., `sb-xxxxx.ondigitalocean.app`)
2. Run Terraform to create DNS records:
   ```bash
   cd /Users/uqapp/sb-betting/do-setup/02-frontend
   terraform apply
   ```
3. DNS records will be created automatically

## Troubleshooting

If you get "unknown field 'components'" error:
- Make sure you're using YAML format, not JSON
- Check that the YAML syntax is correct (indentation matters)
- Try using the web console instead (Option 1)

