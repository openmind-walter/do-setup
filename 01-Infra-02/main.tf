# --- DigitalOcean Container Registry ---

resource "digitalocean_container_registry" "private_registry" {
  name                   = "${var.domain_prefix}${var.app_name}"
  subscription_tier_slug = "${var.subscription_tier}"
  region                 = "${var.region}"
}

# --- Optional: Get Docker Credentials (Highly Recommended) ---
# This resource gets the credentials needed to push/pull images using 'docker login'
resource "digitalocean_container_registry_docker_credentials" "registry_credentials" {
  registry_name = digitalocean_container_registry.private_registry.name
  # Set write = true if you need credentials to push images (default is false/read-only)
  write         = true 
}

# --- Outputs (Connection Details) ---

output "registry_endpoint" {
  description = "The endpoint URL used for pushing and pulling Docker images."
  value       = digitalocean_container_registry.private_registry.endpoint
}

output "registry_server_url" {
  description = "The domain name of the registry."
  value       = digitalocean_container_registry.private_registry.server_url
}

output "docker_login_command" {
  description = "Command to log into the registry."
  value       = "doctl registry login"
}
