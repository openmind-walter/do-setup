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

