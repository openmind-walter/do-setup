resource "digitalocean_vpc" "vpc" {
  name     = "${var.env}" # Name of the VPC
  region   = var.region # Bangalore
  ip_range = "172.16.0.0/16" # IP range of the VPC
}
