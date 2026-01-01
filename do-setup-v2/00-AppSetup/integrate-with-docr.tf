provider "digitalocean" {}

provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.main.endpoint
  token                  = digitalocean_kubernetes_cluster.main.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  )
}

resource "digitalocean_container_registry" "registry" {
  name = "my-registry"
}

data "digitalocean_container_registry_docker_credentials" "docr" {
  registry_name = digitalocean_container_registry.registry.name
}

resource "kubernetes_secret" "docr_pull_secret" {
  metadata {
    name      = "registry-digitalocean-com"
    namespace = "default"
  }

  data = {
    ".dockerconfigjson" = data.digitalocean_container_registry_docker_credentials.docr.docker_credentials
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_service_account" "default" {
  metadata {
    name      = "default"
    namespace = "default"
  }

  image_pull_secret {
    name = kubernetes_secret.docr_pull_secret.metadata[0].name
  }
}
