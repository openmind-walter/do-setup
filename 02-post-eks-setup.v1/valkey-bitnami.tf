
resource "helm_release" "redis01" {
  name       = "${var.env}-redis01"
  namespace  = var.env
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "valkey"
  // chart      = "redis"   # Bitnami Redis chart
  // version    = "17.3.2"
//  version    = "24.0.0"
  // version    = "21.8.1"  # Optional, pin a known valid version

  # Load external YAML
  values = [
    templatefile("./valkey-values.yaml",{SHARED_ENV = var.env})
  ]
}

resource "helm_release" "redis-feed" {
  name       = "${var.env}-feed"
  namespace  = var.env
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "valkey"
  // chart      = "redis"   # Bitnami Redis chart
  // version    = "5.0.10"
  // version    = "21.8.1"  # Optional, pin a known valid version

  # Load external YAML
  values = [
    templatefile("./valkey-values.yaml",{SHARED_ENV = var.env})
  ]
}


resource "helm_release" "redis02" {
  name       = "${var.env}-redis02"
  namespace  = var.env
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "valkey"
  // chart      = "redis"   # Bitnami Redis chart
  // version    = "17.3.2"
  // version    = "21.8.1"  # Optional, pin a known valid version

  # Load external YAML
  values = [
    templatefile("./valkey-values2.yaml",{SHARED_ENV = var.env})
  ]
}