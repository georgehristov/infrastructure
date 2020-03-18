resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}




/*
resource "kubernetes_namespace" "example" {
  metadata {
    name = "example"
  }
}


resource "kubernetes_service" "example" {
  lifecycle {
    //noinspection HILUnresolvedReference
    ignore_changes = [metadata[0].annotations]
  }
  metadata {
    name = "example"
    namespace = "example"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = "example"
    }
    port {
      port = 80
      protocol = "TCP"
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "example" {
  metadata {
    name = "example"
    namespace = "example"
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "example"
      }
    }
    template {
      metadata {
        labels = {
          app = "example"
        }
      }
      spec {
        container {
          name = "nginx"
          image = "digitalocean/doks-example"
          port {
            container_port = 80
            protocol = "TCP"
          }
        }
      }
    }
  }
}
*/

resource "kubernetes_secret" "do-token" {
  metadata {
    name = "acme-dnsprovider-config"
    namespace = "kube-system"
  }

  data = {
    DO_AUTH_TOKEN=var.DIGITALOCEAN_TOKEN
  }

}

resource "random_password" "root" {
  length = 10
}

resource "helm_repository" "bitnami" {
  name = "bitnami"
  url = "https://charts.bitnami.com/bitnami"
}
data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

resource "helm_release" "db" {
  chart = "bitnami/mariadb"
  repository = helm_repository.bitnami.name
  name = "db"

  values = [
    "${file("mariadb.yaml")}"
  ]

  set { name="db.name" value="saasty" }
  set { name="db.user" value="saasty" }
  set { name="db.password" value=random_password.root.result }
}

/*
resource "helm_release" "traefik" {
  chart = "stable/traefik"
  name = "traefik"
  namespace = "kube-system"

  values = [ "${file("helm/traefik.yaml")}" ]

}
*/
