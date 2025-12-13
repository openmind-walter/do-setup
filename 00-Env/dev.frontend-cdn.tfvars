#cricket_fancy_domains = ["openmindsolutions.sg", "sb-demokit.com"]

# Region for DigitalOcean Spaces and App Platform
# Must match the existing app's region (currently "syd")
do_space_region = "syd1"

# Cloudflare configuration
# Get your Account ID from: https://dash.cloudflare.com/ -> Right sidebar -> Account ID
#cloudflare_account_id = "88f306faaa01388478bab55c81ccf19e"
# cloudflare_api_token = "your_api_token_here"  # Set via environment variable or terraform.tfvars

# Zone creation settings (optional)
# create_zones = false  # Set to true to create zones automatically
# cloudflare_zone_plan = "free"  # Options: "free", "pro", "business", "enterprise"
# cloudflare_jump_start = false  # Auto-scan DNS records when creating zone

# Feature flags
enable_rulesets = true  # Set to false if getting 403 errors on rulesets (cache configuration)
# enable_workers = true  # Set to false if Workers are not enabled in your account

# Spaces configuration
spaces_base_url = "https://dev-sb.syd1.digitaloceanspaces.com"
domain_prefix = "dev-"

site_configs = {
  # SITE 1: Mobile site
  mobile_sb_demokit_com = {
    domain_name   = "dev-mobile.sb-demokit.com"
    dns_zone      = "sb-demokit.com"
    path_prefix   = "dev-mobile"
    local_build_dir = "../builds/dev-mobile"
  },
  
  # SITE 2: Admin site
  admin_sb_demokit_com = {
    domain_name   = "dev-admin.sb-demokit.com"
    dns_zone      = "sb-demokit.com"  # Fixed: should match the domain's root zone
    path_prefix   = "dev-admin"
    local_build_dir = "../builds/dev-admin"
  }
}

