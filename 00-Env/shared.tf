
# provider "helm" {
#   kubernetes {
#     config_path = var.kubeconfig_path
#   }
# }

# variable "do_token" {}
# variable "kubeconfig_path" {
#   default = "~/.kube/config"
# }


provider "helm" {
  kubernetes = {
 host  = digitalocean_kubernetes_cluster.k8.endpoint
  token = digitalocean_kubernetes_cluster.k8.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.k8.kube_config[0].cluster_ca_certificate
  )

  }
}

provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.k8.endpoint
  token = digitalocean_kubernetes_cluster.k8.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.k8.kube_config[0].cluster_ca_certificate
  )
}
provider "kubectl" {
  host  = digitalocean_kubernetes_cluster.k8.endpoint
  token = digitalocean_kubernetes_cluster.k8.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.k8.kube_config[0].cluster_ca_certificate
  )
}
