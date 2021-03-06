resource "digitalocean_database_cluster" "db" {
  engine = "mysql"
  name = "atk"
  node_count = 1
  region = "lon1"
  size = "db-s-1vcpu-1gb"
  version = "8"
}
resource "digitalocean_project_resources" "db_atk" {
  project = digitalocean_project.atk.id
  resources = [ digitalocean_database_cluster.db.urn ]
}


module "atk4-apps" {
  source = "../../../root/workspace"
  name = "atk4-apps"
  path = "projects/agiletoolkit.org/apps"
  github_oauth = var.GITHUB_OAUTH
  tfe_org = var.TFE_ORG

  env = {
    TF_VAR_MYSQL_ENDPOINT: "${digitalocean_database_cluster.db.host}:${digitalocean_database_cluster.db.port}" # try private_uri

    # Connects to MySQL and create databases
    MYSQL_ENDPOINT: "${digitalocean_database_cluster.db.host}:${digitalocean_database_cluster.db.port}" # try private_uri
    MYSQL_USERNAME: digitalocean_database_cluster.db.user
    MYSQL_PASSWORD: digitalocean_database_cluster.db.password
    MYSQL_TLS_CONFIG: "skip-verify"

    TF_VAR_MYSQL_USERNAME: digitalocean_database_cluster.db.user
    TF_VAR_MYSQL_PASSWORD: digitalocean_database_cluster.db.password


    # Publishes DNS strings in kubernetes secrets
    TF_VAR_KUBE_HOST: digitalocean_kubernetes_cluster.atk.endpoint
    TF_VAR_KUBE_TOKEN: digitalocean_kubernetes_cluster.atk.kube_config[0].token
    TF_VAR_KUBE_CERT: digitalocean_kubernetes_cluster.atk.kube_config[0].cluster_ca_certificate
  }
}


output "db_database" {
  value = "${digitalocean_database_cluster.db.host}:${digitalocean_database_cluster.db.port}"
}
output "db_user" {
  value = digitalocean_database_cluster.db.user
}
output "db_password" {
  value = digitalocean_database_cluster.db.password
}
