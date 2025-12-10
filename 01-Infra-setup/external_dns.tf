
# resource "helm_release" "externaldns" {
#   name       = "externaldns"
#   namespace  = "kube-system"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "external-dns"
#   version    = "6.29.2" # Check latest: https://artifacthub.io/packages/helm/bitnami/external-dns

#   set {
#     name  = "provider"
#     value = "digitalocean"
#   }

# #   set {
# #     name  = "digitalocean.apiToken"
# #     value = var.digitalocean_token
# #   }

#   set {
#     name  = "policy"
#     value = "sync"
#   }

#   set {
#     name  = "registry"
#     value = "txt"
#   }

#   set {
#     name  = "txtOwnerId"
#     value = "${var.env}-${var.app_name}"
#   }

#   set {
#     name  = "sources[0]"
#     value = "ingress"
#   }

#   # Optional: watch all namespaces or restrict
#   set {
#     name  = "namespace"
#     value = ""
#   }

#   # Optional logging level
#   set {
#     name  = "logLevel"
#     value = "debug"
#   }
# }
