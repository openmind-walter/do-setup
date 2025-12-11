variable "do_token" {
  description = "Your DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "env" {
  type        = string
}

variable "domain_name" {
  type        = string
}

variable "app_name" {
  type        = string
}

variable "domain_prefix" {
  type        = string
}

variable "region" {
  type        = string
  default = "syd1"
}

variable "spaces_access_id" {
  description = "DigitalOcean Spaces Access Key ID"
  type        = string
  sensitive   = true
}

variable "spaces_secret_key" {
  description = "DigitalOcean Spaces Secret Access Key"
  type        = string
  sensitive   = true
}

