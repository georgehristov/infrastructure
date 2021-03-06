variable "a-region" {
  #default = "eu-west-2"
  description = "Which region to use as a default (eu-west-2)"
}
variable "b-infra" {
  description = "Organisational unit - (e.g. club name, client name)"
}

variable "c-email" {
  description = "Admin email for this organisation unit"
}

variable "d-tfe-token" {
  # Security note. This will not be published and will remain on your loc
  description = "Terraform, go to User / Tokens and generate new one. You can remove it after bootstrap."
}

provider "tfe" {
  token = var.d-tfe-token
}

variable "e-do-token" {
  description = "Digital Ocean token"
}
provider "digitalocean" {
  token = var.e-do-token
}


resource "tfe_organization" "org" {
  name = var.b-infra
  email = var.c-email
}

resource "tfe_organization_token" "org_token" {
  organization = tfe_organization.org.name
}

resource "tfe_oauth_client" "oauth" {
  organization     = "atk4"
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.GITHUB_TOKEN
  service_provider = "github"
}

resource "tfe_workspace" "tfe" {
  name = "${var.b-infra}-root"
  organization = tfe_organization.org.id
  working_directory = "root"
  trigger_prefixes = ["/modules"]
  auto_apply = true
  queue_all_runs = false
  vcs_repo {
    identifier = "atk4/infrastructure"
    oauth_token_id = tfe_oauth_client.oauth.oauth_token_id
  }
}

variable "GITHUB_TOKEN" {}
locals {
  env = {
    TF_VAR_DIGITALOCEAN_TOKEN: var.e-do-token
    TF_VAR_GITHUB_OAUTH: tfe_oauth_client.oauth.oauth_token_id
    TF_VAR_GITHUB_TOKEN: var.GITHUB_TOKEN
    TF_VAR_TFE_TOKEN: tfe_organization_token.org_token.token

    TFE_TOKEN: tfe_organization_token.org_token.token
  }
}

resource "tfe_variable" "tfe_var" {
  for_each = local.env
  workspace_id = tfe_workspace.tfe.id
  category = "env"
  key = each.key
  value = each.value
  sensitive = true
}


resource "tfe_variable" "tfe_var_org" {
  workspace_id = tfe_workspace.tfe.id
  category = "env"
  key = "TF_VAR_TFE_ORG"
  value = var.b-infra
}
