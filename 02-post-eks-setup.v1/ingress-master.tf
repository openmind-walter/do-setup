resource "kubectl_manifest" "deploy_master_ingress" {
  yaml_body = templatefile("./ingress-master.yaml", {
      NAME_SPACE = data.kubernetes_namespace_v1.ns.metadata[0].name
      # PREFIX = ""
      PREFIX = "${data.kubernetes_namespace_v1.ns.metadata[0].name}-"
      DOMAIN_NAME = var.domain_name
      DOMAIN = replace(var.domain_name, ".","-"),
      APP_NAME = var.app_name
      CERTIFICATE_ID = "test" #digitalocean_certificate.cert.id
  })
  # depends_on = [helm_release.nginx_ingress, digitalocean_certificate.cert]
}
