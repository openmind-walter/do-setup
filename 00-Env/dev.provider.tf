terraform {
#    backend "s3" {
#    profile    = "dev" 
#    bucket     = "dev-terraform-phoenix"
#   key        = "s3-buckets/dev-terraform-infra.tfstate"
#    #shared_credentials_file = "~/.aws/credentials"
#    region     = "us-east-1"
#    endpoint   = "https://sgp1.digitaloceanspaces.com"
#    skip_region_validation      = true
#    skip_credentials_validation = true
#  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.36.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  kubectl = {
    source  = "gavinbunney/kubectl"
    version = ">= 1.14.0"
  }
  helm = {
    source  = "hashicorp/helm"
    version = ">= 2.9.0"
  }
  cloudflare = {
  source  = "cloudflare/cloudflare"
  version = "~> 4.0"
}
  }
}
