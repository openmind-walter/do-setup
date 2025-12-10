resource "kubernetes_namespace_v1" "ns" {
  metadata {
    name = "${var.env}"
  }
  depends_on = [digitalocean_kubernetes_cluster.k8]
}