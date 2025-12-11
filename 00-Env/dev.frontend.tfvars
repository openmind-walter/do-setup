domain_names = ["openmindsolutions.sg", "sb-demokit.com"]

#cricket_fancy_domains = ["openmindsolutions.sg", "sb-demokit.com"]

# Region for DigitalOcean Spaces and App Platform
# Must match the existing app's region (currently "syd")
do_space_region = "syd1"

# GitHub repository configuration for App Platform components
github_repo   = "openmind-walter/dummy-fe"
github_branch = "dev"

site_configs = {
  # SITE 1: The 'key' (site_a) becomes the unique component name in App Platform
  mobile_openmindsolutions_sg = {
    domain_name   = "dev-mobile.openmindsolutions.sg"
    dns_zone      = "openmindsolutions.sg"
    bucket_name = "dev-sb"
    source_dir    = "dev-mobile_openmindsolutions_sg/dist"
  },
  
  # SITE 2: Adding a new site just means adding a new block here
  # mobile_demokit_com = {
  #   domain_name   = "dev-mobile.sb-demokit.com"
  #   dns_zone      = "sb-demokit.com"
  #   bucket_name = "dev-sb"
  #   source_dir    = "/dist/dev-mobile_sb-demokit_com"
  # }
}
