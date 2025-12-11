# Remove Secret from Git History

GitHub detected a DigitalOcean Personal Access Token in `02-frontend/.env` that was committed. Here's how to fix it:

## Option 1: Remove from History (Recommended)

### Step 1: Remove the file from git history

```bash
cd /Users/uqapp/sb-betting/do-setup

# Remove .env from all commits
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch 02-frontend/.env" \
  --prune-empty --tag-name-filter cat -- --all

# Or use git filter-repo (if installed, cleaner method):
# git filter-repo --path 02-frontend/.env --invert-paths
```

### Step 2: Force push (⚠️ WARNING: This rewrites history)

```bash
# Force push to remove the secret from remote
git push origin --force --all
git push origin --force --tags
```

### Step 3: Rotate the exposed token

1. Go to: https://cloud.digitalocean.com/account/api/tokens
2. Revoke the exposed token
3. Create a new token
4. Update your local `.env` file and `dev.tfvars` with the new token

## Option 2: Use GitHub's Unblock Feature (Not Recommended)

If you want to allow the secret (not recommended for security):

1. Visit: https://github.com/openmind-walter/do-setup/security/secret-scanning/unblock-secret/36hfBrIadue9B6gwJfgUlw9KiHx
2. Follow the prompts to allow the secret

**⚠️ WARNING**: This exposes your token publicly. Rotate it immediately after.

## Option 3: Create a New Branch Without the Secret

If you can't rewrite history:

```bash
# Create a new branch from before the commit with the secret
git checkout <commit-before-ca5058d>
git checkout -b main-clean

# Cherry-pick commits after removing .env
# Then force push the new branch
```

## Prevention

The `.env` file is now in `.gitignore`. To prevent this in the future:

1. **Never commit `.env` files** - They're already in `.gitignore`
2. **Use environment variables** - Set tokens via `export TF_VAR_do_token=...`
3. **Use secret management** - Consider using Terraform Cloud, AWS Secrets Manager, etc.
4. **Use `.env.example`** - Create example files without real values

## Current Status

- ✅ `.env` is in `.gitignore` (won't be committed again)
- ❌ Secret is still in git history (needs removal)
- ⚠️ Token should be rotated (it's been exposed)

