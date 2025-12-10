# Create App from private GitHub repo
resource "digitalocean_app" "angular" {
  spec {
    name   = "${var.domain_prefix}${var.app_name}"
    region = substr(var.region, 0, length(var.region) - 1)

    # Static Site (Free Tier)
    static_site {
      name          = "${var.domain_prefix}${var.app_name}"
      output_dir    = "/"  # Points to your built Angular files
      source_dir    = "browser"
      error_document = "index.html"  # For Angular routing

      github {
        repo           = "openmind-walter/events-fe"
        branch         = var.env
        deploy_on_push = true
      }
    }

    # Optional: Add a custom domain
    domain {
      name = "${var.domain_prefix}${var.app_name}.${var.domain_name}"
      # type = "PRIMARY"
      zone = var.domain_name
    }
  }
}

resource "digitalocean_record" "app_cname" {
  domain = var.domain_name                       # e.g., "mydomain.com"
  type   = "CNAME"
  name   = "${var.domain_prefix}${var.app_name}" # e.g., "dev-sb"
  value  = "${replace(digitalocean_app.angular.default_ingress, "https://", "")}." 
}

# Output the live URL
output "app_url" {
  value = digitalocean_app.angular.live_url
}
