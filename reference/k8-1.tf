# resource "digitalocean_kubernetes_cluster" "events" {
#   name    = "events-cluster"
#   region  = "blr1"  # Replace with your desired region, e.g., "nyc1"
#   version = "1.31.1-do.3"   # Replace with your desired Kubernetes version => doctl kubernetes options versions
#   vpc_uuid = digitalocean_vpc.vpc.id

#   node_pool {
#     name       = "events-pool"
#     size       = "s-2vcpu-2gb"
#     auto_scale = false
#     # min_nodes  = 2
#     # max_nodes  = 3
#     node_count = 1
#     tags       = ["events"]
#     labels = {
#       service  = "api-rust"
#       priority = "high"
#     }
#   }
# }


# output "kubernetes_cluster_output" {
#   value = digitalocean_kubernetes_cluster.events.kube_config.0.raw_config # Output the raw kubeconfig
#   description = "The raw kubeconfig of the created cluster" # Description of the output
#   sensitive = true # Mark the output as sensitive
# }

