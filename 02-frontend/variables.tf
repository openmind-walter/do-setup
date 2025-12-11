variable "do_space_region" {
  description = "The region where the DigitalOcean Spaces will be created."
  type        = string
  default     = "syd1" 
}

variable "site_configs" {
  description = "Map of sites to deploy. Key is a unique name (e.g., 'site_a', 'site_b')."
  type = map(object({
    # The full domain name for the site (e.g., www.mysite.com)
    domain_name = string
    # The root domain to use for DNS management (e.g., mysite.com)
    dns_zone    = string
    # The unique name for the Spaces bucket (must be globally unique)
    bucket_name = string 
    # The path *inside* the Space where the site files are pushed (e.g., dist)
    source_dir  = string
  }))
}

variable "github_repo" {
  description = "GitHub repository for the frontend application"
  type        = string
  default     = "openmind-walter/dummy-fe"
}

variable "github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "dev"
}

# Note: spaces_access_id and spaces_secret_key are inherited from parent module (00-Env)