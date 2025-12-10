data "kubernetes_namespace_v1" "ns" {
  metadata {
    name = "${var.env}"
  }
}