# Will install traefik here

data "helm_repository" "helm" {
  name = "helm"
  url = "https://kubernetes-charts.storage.googleapis.com"
}

resource "kubernetes_secret" "do-token" {
  metadata {
    name = "acme-dnsprovider-config"
    namespace = "kube-system"
  }

  data = {
    DO_AUTH_TOKEN=var.DIGITALOCEAN_TOKEN
  }

}

resource "helm_release" "traefik" {
  chart = "traefik"
  name = "traefik"
  namespace = "kube-system"
  repository = data.helm_repository.helm.url

//  set {
//    name = "configs.secret.argocdServerAdminPassword"
//    value = bcrypt(random_password.argo.result)
//  }

  values = [
    <<YAML
dashboard:
  enabled: true
  domain: traefik.agiletoolkit.org
kubernetes:
  ingressEndpoint:
    hostname: abc
rbac:
  enabled: true
ssl:
  enabled: true
  enforced: true
acme:
  enabled: true
  staging: false
  email: me@nearly.guru
  logging: true
  challengeType: "dns-01"
  domains:
    enabled: true
    domainsList:
      - main: "*.saasty.net"
  dnsProvider:
    name: digitalocean
    existingSecretName: acme-dnsprovider-config
YAML
  ]

  lifecycle {
    ignore_changes = [
      set
      # password value seems to always change
    ]
  }
}

data "kubernetes_service" "traefik" {
  depends_on = [helm_release.traefik]
  metadata {
    namespace = "kube-system"
    name = "traefik"
  }
}

output "ip" {
  value = data.kubernetes_service.traefik.load_balancer_ingress.0.ip
}

resource "digitalocean_record" "traefik" {
  domain = "agiletoolkit.org"
  type = "A"
  name = "traefik"
  ttl = 60
  value = data.kubernetes_service.traefik.load_balancer_ingress[0].ip
}
