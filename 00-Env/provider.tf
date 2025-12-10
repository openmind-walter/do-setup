terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  kubectl = {
    source  = "gavinbunney/kubectl"
    version = ">= 1.14.0"
  }
  helm = {
    source  = "hashicorp/helm"
    version = ">= 2.6.0"
  }
  }
}


# -----------------------
# PROVIDERS & VARIABLES
# -----------------------
provider "digitalocean" {
  token = var.do_token
}
