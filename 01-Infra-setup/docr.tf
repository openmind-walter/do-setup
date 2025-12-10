
# # Create Container Registry
# resource "digitalocean_container_registry" "events" {
#   name                   = var.app_name
#   subscription_tier_slug = "basic"  # Options: basic ($5/mo), professional ($15/mo), enterprise ($30/mo)
# #  region                 = "blr1"    # Supported: nyc3, sfo3, ams3, sgp1, fra1
#   region = var.region

# }

# # Generate and output read/write credentials (store securely!)
# resource "digitalocean_container_registry_docker_credentials" "creds" {
#   registry_name = digitalocean_container_registry.events.name
#   write         = true
# }

# # Output registry endpoint and credentials
# output "registry_endpoint" {
#   value = digitalocean_container_registry.events.endpoint
# }

# output "registry_server" {
#   value = digitalocean_container_registry.events.server_url
# }

# output "docker_config_json" {
#   value     = digitalocean_container_registry_docker_credentials.creds.docker_credentials
#   sensitive = true
# }