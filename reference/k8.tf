# resource "kubernetes_secret" "docr_pull_secret" {
#   metadata {
#     name = "docr-pull-secret"
#     namespace = "default"  # Change if using custom namespaces
#   }

#   data = {
#     ".dockerconfigjson" = digitalocean_container_registry_docker_credentials.creds.docker_credentials
#   }

#   type = "kubernetes.io/dockerconfigjson"
# }


# # -----------------------
# # KUBERNETES CLUSTER
# # -----------------------
# resource "digitalocean_kubernetes_cluster" "main" {
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
#     tags       = ["events-pool"]
#     labels = {
#       service  = "events"
#       priority = "high"
#     }
#   }
#     # Automatically configure cluster to use DOCR
#   registry_integration {
#     registry = digitalocean_container_registry.events_registry.id
#   }
# }

# # -----------------------
# # OPTIONAL: Output Kubeconfig
# # -----------------------
# output "kubeconfig" {
#   value = digitalocean_kubernetes_cluster.main.kube_config[0].raw_config
#   sensitive = true
# }



# # -----------------------
# # HELM: CloudNativePG Operator
# # -----------------------
# resource "helm_release" "cloudnativepg" {
#   name       = "cloudnativepg"
#   repository = "https://cloudnative-pg.github.io/charts"
#   chart      = "cloudnative-pg"
#   namespace  = "cnpg-system"
#   create_namespace = true
#     set {
#     name = "image.tag"
#     value = "1.22.0"
#   }  
#   # set {
#   #   name = "nodeSelector.service"
#   #   value = "app"
#   # }
# }

# # -----------------------
# # POSTGRES SECRET
# # -----------------------
# resource "kubernetes_secret" "pg_secret" {
#   metadata {
#     name      = "pg-secret"
#     namespace = "default"
#   }

#   data = {
#     username = base64encode("admin")
#     password = base64encode("SuperSecret123")
#   }
#   type = "Opaque"
# }

# # -----------------------
# # DO SPACES SECRET (S3)
# # -----------------------
# resource "kubernetes_secret" "s3_credentials" {
#   metadata {
#     name      = "s3-credentials"
#     namespace = "default"
#   }

#   data = {
#     access-key = base64encode(var.spaces_key)
#     secret-key = base64encode(var.spaces_secret)
#   }
#   type = "Opaque"
# }

# variable "spaces_key" {}
# variable "spaces_secret" {}

