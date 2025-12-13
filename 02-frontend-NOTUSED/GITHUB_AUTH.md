# GitHub Authentication for DigitalOcean App Platform

## Error
```
Error: Error creating App: POST https://api.digitalocean.com/v2/apps: 400 
GitHub user not authenticated
```

## Solution

You need to connect your GitHub account to DigitalOcean before Terraform can create apps with GitHub sources.

### Step 1: Connect GitHub to DigitalOcean

1. Go to: https://cloud.digitalocean.com/account/api/integrations
2. Click **"Connect GitHub"** or **"Add GitHub"**
3. Authorize DigitalOcean to access your GitHub repositories
4. Select the repositories you want to give access to (or select "All repositories")

### Step 2: Verify Connection

After connecting, you should see your GitHub account listed in the integrations page.

### Step 3: Retry Terraform Apply

Once GitHub is connected, run:

```bash
cd /Users/uqapp/sb-betting/do-setup/02-frontend
terraform apply
```

## Alternative: Use a Different Source

If you don't want to connect GitHub, you can use other source types:
- **GitLab**: Connect GitLab instead
- **Image**: Use a Docker image from a registry
- **Local**: Upload files directly (not recommended for CI/CD)

For static sites, GitHub integration is the most common approach.

## Troubleshooting

**"GitHub user not authenticated" even after connecting:**
- Make sure you authorized the correct GitHub account
- Check that the repository `openmind-walter/dummy-fe` is accessible
- Verify the repository exists and you have access to it
- Try disconnecting and reconnecting GitHub

**Repository not found:**
- Verify the repository name: `openmind-walter/dummy-fe`
- Check that the repository is not private (or that you've granted access)
- Ensure the branch `dev` exists in the repository

