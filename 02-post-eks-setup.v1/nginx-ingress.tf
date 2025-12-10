resource "helm_release" "nginx_ingress" {
  name       = "${var.env}"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = data.kubernetes_namespace_v1.ns.metadata[0].name
  # https://artifacthub.io/packages/helm/bitnami/nginx-ingress-controller
  set = [{
    name  = "ingressClassResource.name"
    value = "nginx-${var.env}"
  }
  ]
  values = [
    templatefile("./nginx-values.yaml",{
      DOMAIN_NAME = var.domain_name,
      SHARED_ENV = data.kubernetes_namespace_v1.ns.metadata[0].name,
      CERTIFICATE_ID = "TEST" #digitalocean_certificate.cert.id
    })
  ]
#  depends_on = [digitalocean_certificate.cert]
}


# resource "digitalocean_reserved_ip" "ingress_ip" {
#   region = var.region
# }

# resource "digitalocean_reserved_ip_assignment" "ingress_ip" {
#   ip_address = digitalocean_reserved_ip.ingress_ip.ip_address
#   droplet_id = digitalocean_kubernetes_cluster.k8.node_pool[0].nodes[0].droplet_id
# }

# # Terraform Firewall
# resource "digitalocean_firewall" "ingress" {
#   name = "ingress-https"
#   droplet_ids = [for node in digitalocean_kubernetes_cluster.k8.node_pool[0].nodes : node.droplet_id]

#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "80"
#     source_addresses = ["0.0.0.0/0"]
#   }

#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "443"
#     source_addresses = ["0.0.0.0/0"]
#   }
# }

# resource "digitalocean_record" "ingress" {
#   domain = var.domain_name
#   type   = "A"
#   name   = "${var.domain_prefix}api-rust"
#   value  = digitalocean_reserved_ip.ingress_ip.ip_address
# }


# resource "kubernetes_ingress_v1" "api_ingress" {
#   metadata {
#     name      = "api-ingress"
#     namespace = var.env

#     annotations = {
#       "service.beta.kubernetes.io/do-loadbalancer-enable-proxy-protocol" = "true"
#       "nginx.ingress.kubernetes.io/use-proxy-protocol"                   = "true"
#     }
#   }

#   spec {
#     tls {
#       secret_name = "do-managed-tls-secret" # DO will manage this
#       hosts       = [var.domain_name]
#     }

#     rule {
#       host = var.domain_name

#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"

#           backend {
#             service {
#               name = "${var.domain_prefix}api-rust" # Replace this
#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# Fetch the LoadBalancer service created by NGINX
# resource "null_resource" "wait_for_lb_ip" {
#   provisioner "local-exec" {
#     command = "./get-nginx-ip.sh ${kubernetes_namespace_v1.ns.metadata[0].name}"
#   }

#   depends_on = [helm_release.nginx_ingress]
# }

data "external" "nginx_lb_ip" {
  program = ["bash", "${path.module}/get-nginx-ip.sh", data.kubernetes_namespace_v1.ns.metadata[0].name]
  depends_on = [helm_release.nginx_ingress]
}


# Create DNS A record
resource "digitalocean_record" "api_dns" {
  domain = var.domain_name
  type   = "A"
  name   = "${var.env}-${var.app_name}-api-rust"
  value  = data.external.nginx_lb_ip.result.ip
  ttl    = 60
}

# resource "digitalocean_record" "api_dns" {
#   domain = var.domain_name  # e.g., example.com
#   type   = "A"
#   name   = "${var.env}-${var.app_name}-api-rust"            # for api.example.com
#   value  = helm_release.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
#   ttl    = 60
# }
# output "nginx_lb_ip" {
#   value = helm_release.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
#   description = "The external IP of the NGINX ingress LoadBalancer"
# }