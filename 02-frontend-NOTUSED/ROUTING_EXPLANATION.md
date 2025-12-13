# DNS-Based Routing Configuration

## How It Works

Your configuration creates a **multi-site setup** where each domain serves content from its corresponding directory:

### Architecture

```
dev-mobile.openmindsolutions.sg (DNS CNAME)
    ↓
App Platform (sb-xxxxx.ondigitalocean.app)
    ↓
Static Site: mobile-openmindsolutions-sg
    ↓
Serves from: dev-mobile_openmindsolutions_sg/dist
```

### Current Setup

1. **Static Site**: `mobile-openmindsolutions-sg`
   - Serves content from: `dev-mobile_openmindsolutions_sg/dist`
   - GitHub repo: `openmind-walter/dummy-fe`
   - Branch: `dev`

2. **DNS Record**: 
   - `dev-mobile.openmindsolutions.sg` → CNAME → App's `live_url`

3. **Routing**:
   - When you visit `dev-mobile.openmindsolutions.sg`, DNS resolves to the app
   - App Platform serves the static site content from the configured `source_dir`

## Adding More Sites

To add more sites, simply add entries to `site_configs` in `dev.frontend.tfvars`:

```hcl
site_configs = {
  mobile_openmindsolutions_sg = {
    domain_name   = "dev-mobile.openmindsolutions.sg"
    dns_zone      = "openmindsolutions.sg"
    bucket_name   = "dev-sb"
    source_dir    = "dev-mobile_openmindsolutions_sg/dist"
  },
  
  mobile_demokit_com = {
    domain_name   = "dev-mobile.sb-demokit.com"
    dns_zone      = "sb-demokit.com"
    bucket_name   = "dev-sb"
    source_dir    = "dev-mobile_sb-demokit_com/dist"
  }
}
```

Terraform will automatically:
- Create a static_site for each entry
- Create DNS records for each domain
- Configure routing

## Important Notes

1. **Static Site Names**: Converted from underscores to hyphens (e.g., `mobile_openmindsolutions_sg` → `mobile-openmindsolutions-sg`)

2. **Source Directory**: Must match the path in your GitHub repo where built files are located

3. **DNS Propagation**: After DNS records are created, wait 5-15 minutes for propagation

4. **Content Deployment**: Ensure your GitHub repo has the built files in the specified `source_dir` paths

## Verification

After deployment:
1. Check app has `live_url`: `terraform output app_cname_target`
2. Verify DNS records: `dig dev-mobile.openmindsolutions.sg`
3. Visit the domain in browser to see content

