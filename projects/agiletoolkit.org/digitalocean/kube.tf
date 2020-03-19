data "digitalocean_kubernetes_versions" "example" {}

resource "digitalocean_kubernetes_cluster" "atk" {
  name = "atk"
  region = "lon1"
  #version = data.digitalocean_kubernetes_versions.example.latest
  version = "1.16.6-do.2"
  tags = ["production"]
  //noinspection MissingProperty
  node_pool {
    name = "worker-pool"
    size = "s-1vcpu-2gb"
    # node_count = 1
    auto_scale = true
    min_nodes = 1
    max_nodes = 2
  }
}

variable "GITHUB_OAUTH" {}
variable "TFE_ORG" {}
variable "DIGITALOCEAN_TOKEN" {}

module "atk4-kube" {
  source = "../../../root/workspace"
  name = "atk4-kube"
  path = "projects/agiletoolkit.org/kube"
  github_oauth = var.GITHUB_OAUTH
  tfe_org = var.TFE_ORG

  env = {
    TF_VAR_KUBE_HOST: digitalocean_kubernetes_cluster.atk.endpoint
    TF_VAR_KUBE_TOKEN: digitalocean_kubernetes_cluster.atk.kube_config[0].token
    TF_VAR_KUBE_CERT: digitalocean_kubernetes_cluster.atk.kube_config[0].cluster_ca_certificate

    TF_VAR_DIGITALOCEAN_TOKEN: digitalocean_kubernetes_cluster.atk.kube_config[0].cluster_ca_certificate
    TF_VAR_DIGITALOCEAN_TOKEN: var.DIGITALOCEAN_TOKEN
  }
}

resource "digitalocean_volume" "db" {
  name = "db"
  region = "lon1"
  size = 100
  description = "MySQL volume to be attached into k8s cluster"
}



provider "k8s" {
  load_config_file = "false"

  host = digitalocean_kubernetes_cluster.atk.endpoint

  client_certificate     = "${file("~/.kube/client-cert.pem")}"
  client_key             = "${file("~/.kube/client-key.pem")}"
  cluster_ca_certificate = "${file("~/.kube/cluster-ca-cert.pem")}"



}
