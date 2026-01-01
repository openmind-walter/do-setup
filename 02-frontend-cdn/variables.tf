variable "do_space_region" {
  description = "The region where the DigitalOcean Spaces will be created."
  type        = string
  default     = "syd1" 
}


variable "spaces_base_url" {
  type    = string
  default = "https://dev-sb.syd1.digitaloceanspaces.com"
}

# Note: domain_prefix is inherited from parent module (00-Env)

variable "site_configs" {
  description = "Map of sites to deploy. Key is a unique name (e.g., 'site_a', 'site_b')."
  type = map(object({
    # The full domain name for the site (e.g., www.mysite.com)
    domain_name = string
    # The root domain to use for DNS management (e.g., mysite.com)
    dns_zone    = string
    # path_prefix = string
    local_build_dir = string
    # The unique name for the Spaces bucket (must be globally unique)
    # bucket_name = string 
    # The path *inside* the Space where the site files are pushed (e.g., dist)
    # source_dir  = string
  }))
}
variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID (required for Workers)"
  type        = string
}

variable "create_zones" {
  description = "Whether to create Cloudflare zones if they don't exist. Set to false to use existing zones only."
  type        = bool
  default     = false
}

variable "cloudflare_zone_plan" {
  description = "Cloudflare zone plan (free, pro, business, enterprise)"
  type        = string
  default     = "free"
}

variable "cloudflare_jump_start" {
  description = "Whether to automatically scan DNS records when creating a zone"
  type        = bool
  default     = false
}

variable "enable_workers" {
  description = "Whether to create Cloudflare Workers (requires Workers to be enabled in account)"
  type        = bool
  default     = true
}

variable "enable_rulesets" {
  description = "Whether to create Cloudflare Rulesets for cache configuration (requires proper permissions)"
  type        = bool
  default     = true
}

variable "api_domain" {
  description = "API domain name (e.g., 'demo-api.sb-demokit.com') - common for all sites"
  type        = string
  default     = ""
}

variable "api_backend_ip" {
  description = "Backend IP address for the API domain (if not using Cloudflare proxy)"
  type        = string
  default     = ""
}

# Note: spaces_access_id and spaces_secret_key are inherited from parent module (00-Env)