# resource "kubectl_manifest" "cnpg_postgres" {
#     yaml_body = templatefile("./local-cloudnativepg-db.yaml", {
#       NAME_SPACE = data.kubernetes_namespace.ns.metadata[0].name
#       DOMAIN_PREFIX = "${var.env}_"
#       APP_NAME = "${var.app_name}"
#     })
#     depends_on = [helm_release.cloudnativepg]
# }

# # resource "kubectl_manifest" "postgres_secret" {
# #     yaml_body = templatefile("./local-cloudnativepg-secret.yaml", {
# #       NAME_SPACE = kubernetes_namespace.ns.metadata[0].name
# #       PREFIX = "${var.domain_prefix}"
# #     })
# #     depends_on = [helm_release.cloudnativepg]
# # }

# # resource "kubectl_manifest" "readonly_user" {
# #     yaml_body = templatefile("./local-cloudnativepg-configmap.yaml", {
# #       NAME_SPACE = kubernetes_namespace.ns.metadata[0].name
# #       DOMAIN_PREFIX = "${var.domain_prefix}"
# #       APP_NAME = "${var.app_name}"
# #     })
# #     depends_on = [helm_release.cloudnativepg]
# # }


# resource "helm_release" "cloudnativepg" {
#   name       = "cloudnativepg"
#   repository = "https://cloudnative-pg.github.io/charts"
#   chart      = "cloudnative-pg"
#   namespace  = "cnpg-system"
#   create_namespace = true
#   # depends_on = [digitalocean_kubernetes_cluster.k8]
# }
