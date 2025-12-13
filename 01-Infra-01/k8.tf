resource "digitalocean_kubernetes_cluster" "k8" {
  name    = "${var.domain_prefix}${var.app_name}"
  region  = var.region
  version = "1.34.1-do.1"
  vpc_uuid = digitalocean_vpc.vpc.id

  # ------------------------------
  # Default Node Pool
  # ------------------------------
  node_pool {
    name       = "${var.domain_prefix}${var.app_name}-pool"
    size       = "s-2vcpu-4gb"
    auto_scale = false
    node_count = 1
    tags       = ["${var.domain_prefix}${var.app_name}"]
  }
}

# Feed node pool
resource "digitalocean_kubernetes_node_pool" "feed" {
  cluster_id = digitalocean_kubernetes_cluster.k8.id
  name       = "feed-pool"
  size       = "s-2vcpu-4gb"
  node_count = 1
  auto_scale = true
  min_nodes  = 1
  max_nodes  = 5

  labels = {
    role     = "feed"
    workload = "market-data"
  }

  tags = ["feed-pool"]
}

# DB node pool
resource "digitalocean_kubernetes_node_pool" "db" {
  cluster_id = digitalocean_kubernetes_cluster.k8.id
  name       = "db-pool"
  size       = "s-2vcpu-4gb"
  node_count = 1
  auto_scale = false

  labels = {
    role     = "db"
    workload = "postgres-redis"
  }

  tags = ["db-pool"]
}


output "kubernetes_cluster_output" {
  value = digitalocean_kubernetes_cluster.k8.kube_config.0.raw_config # Output the raw kubeconfig
  description = "The raw kubeconfig of the created cluster" # Description of the output
  sensitive = true # Mark the output as sensitive
}

