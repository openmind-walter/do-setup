# Build Error Troubleshooting

## Error
```
BuildJobExitNonZero: Your build job failed because it returned a non-zero exit code.
Component: mobile-openmindsolutions-sg
```

## Common Causes

### 1. Source Directory Doesn't Exist

Your `source_dir` is set to: `dev-mobile_openmindsolutions_sg/dist`

**Check:**
- Does this directory exist in your GitHub repo (`openmind-walter/dummy-fe` branch `dev`)?
- Are the built files already committed to the repo?

**Solutions:**

**Option A: If files are already built and in the repo**
- Verify the path exists: `dev-mobile_openmindsolutions_sg/dist/index.html`
- If the path is different, update `source_dir` in `dev.frontend.tfvars`

**Option B: If files need to be built**
- Add a `build_command` to your static site configuration
- Example: `build_command = "npm install && npm run build"`

**Option C: If files are at the root**
- Change `source_dir` to `/` or the actual path where `index.html` is located

### 2. Missing Build Command

If your repo needs to build the static files, you need to add a `build_command`.

**Add to Terraform:**
```hcl
build_command = "npm install && npm run build"
```

### 3. Check Build Logs

1. Go to: https://cloud.digitalocean.com/apps
2. Click on your app
3. Click on the failed deployment
4. View the build logs to see the exact error

### 4. Verify Repository Structure

Check your GitHub repo structure:
```bash
# Clone and check
git clone https://github.com/openmind-walter/dummy-fe.git
cd dummy-fe
git checkout dev
ls -la dev-mobile_openmindsolutions_sg/dist/
```

## Quick Fixes

### Fix 1: Use Root Directory (if files are at root)
In `dev.frontend.tfvars`, change:
```hcl
source_dir = "/"
```

### Fix 2: Add Build Command
In `main.tf`, add to the static_site block:
```hcl
build_command = "npm install && npm run build"
```

### Fix 3: Verify Path
Make sure the path in `source_dir` matches exactly where your `index.html` is in the repo.

## Next Steps

1. **Check the build logs** in DigitalOcean console for the exact error
2. **Verify the repository structure** matches your `source_dir` path
3. **Add build_command** if files need to be built
4. **Update source_dir** if the path is incorrect

## Getting Build Logs

```bash
# Get app ID
terraform output parent_app_id

# View logs via doctl
doctl apps logs <app_id> --type build --component mobile-openmindsolutions-sg
```

