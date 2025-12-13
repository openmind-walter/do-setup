resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
  depends_on = [digitalocean_kubernetes_cluster.k8]
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.4"
  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]
  depends_on = [kubernetes_namespace_v1.cert_manager]
}

# resource "time_sleep" "wait_for_crds" {
#   depends_on = [helm_release.cert_manager]
#   create_duration = "30s"
# }

# resource "digitalocean_certificate" "cert" {
#   name    = "${var.env}-${var.app_name}-certs"
#   type    = "lets_encrypt"
#   domains = ["${var.env}-${var.app_name}-api-rust.${var.domain_name}"]
# }

# output "certificate_id" {
#   value = digitalocean_certificate.cert.id
#   description = "The ID of the DigitalOcean certificate"
# }

# output "certificate_status" {
#   value = digitalocean_certificate.cert.state
#   description = "The status of the DigitalOcean certificate"
# }

# resource "kubernetes_manifest" "letsencrypt_staging_issuer" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "ClusterIssuer"
#     "metadata" = {
#       "name" = "letsencrypt-staging"
#     }
#     "spec" = {
#       "acme" = {
#         "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
#         "email"  = "kwchess@gmail.com"
#         "privateKeySecretRef" = {
#           "name" = "letsencrypt-staging"
#         }
#         "solvers" = [
#           {
#             "http01" = {
#               "ingress" = {
#                 "ingressClassName" = "nginx-${data.kubernetes_namespace.ns.metadata[0].name}"
#                 "podTemplate" = {
#                   "spec" = {
#                     "nodeSelector" = {
#                       "kubernetes.io/os" = "linux"
#                     }
#                   }
#                 }
#               }
#             }
#           }
#         ]
#       }
#     }
#   }
#   depends_on = [helm_release.cert_manager, time_sleep.wait_for_crds]
# }

# resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "ClusterIssuer"
#     "metadata" = {
#       "name" = "letsencrypt-prod"
#     }
#     "spec" = {
#       "acme" = {
#         "server" = "https://acme-v02.api.letsencrypt.org/directory"
#         "email"  = "kwchess@gmail.com"
#         "privateKeySecretRef" = {
#           "name" = "letsencrypt-prod"
#         }
#         "solvers" = [
#           {
#             "http01" = {
#               "ingress" = {
#                 "ingressClassName" = "nginx-${data.kubernetes_namespace.ns.metadata[0].name}"
#                 "podTemplate" = {
#                   "spec" = {
#                     "nodeSelector" = {
#                       "kubernetes.io/os" = "linux"
#                     }
#                   }
#                 }
#               }
#             }
#           }
#         ]
#       }
#     }
#   }
#   depends_on = [helm_release.cert_manager, time_sleep.wait_for_crds]
# }
