terraform {
   backend "s3" {
    profile    = "dev" 
    bucket     = "sb-demokit"
    key        = "infra/dev-terraform-infra.tfstate"
    #shared_credentials_file = "~/.aws/credentials"
    region     = "syd1" # Often needs to be us-east-1 for S3 compatibility compatibility
    # New syntax for the endpoint
    endpoints = {
      s3 = "https://syd1.digitaloceanspaces.com"
    }
    # Mandatory flags for DigitalOcean Spaces
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true  # <--- This fixes the "Retrieving AWS account details" error
    skip_metadata_api_check     = true
    skip_s3_checksum            = true  # Recommended for DO Spaces
  }
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
