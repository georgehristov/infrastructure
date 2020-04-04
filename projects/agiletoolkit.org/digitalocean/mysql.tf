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


module "atk4-db" {
  source = "../../../root/workspace"
  name = "atk4-db"
  path = "projects/agiletoolkit.org/db"
  github_oauth = var.GITHUB_OAUTH
  tfe_org = var.TFE_ORG

  env = {
    TF_VAR_MYSQL_ENDPOINT: digitalocean_database_cluster.db.uri # try private_uri

    MYSQL_ENDPOINT: digitalocean_database_cluster.db.uri # try private_uri
    MYSQL_USERNAME: digitalocean_database_cluster.db.user
    MYSQL_PASSWORD: digitalocean_database_cluster.db.password
    MYSQL_TLS_CONFIG: "true"


    #TF_VAR_DIGITALOCEAN_TOKEN: var.DIGITALOCEAN_TOKEN
    #DIGITALOCEAN_TOKEN: var.DIGITALOCEAN_TOKEN
  }
}


output "db_database" {
  value = digitalocean_database_cluster.db.database
}
output "db_user" {
  value = digitalocean_database_cluster.db.user
}
output "db_password" {
  value = digitalocean_database_cluster.db.password
}