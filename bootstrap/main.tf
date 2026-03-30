terraform {
  required_version = ">= 1.11.0"

  backend "s3" {
    key    = "eshgham-cron-deploy/terraform.tfstate"
    encrypt = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

variable "gh_token" {
  description = "GitHub token for ESHGHAM runs. Stored as TF_VAR_gh_token in GitHub Actions secrets."
  type        = string
  sensitive   = true
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform/OpenTofu state. Stored as TF_STATE_BUCKET in GitHub Actions secrets."
  type        = string
  sensitive   = true
}


provider "aws" {
  region = local.aws_region
}

provider "github" {
  owner = split("/", local.github_repository)[0]
}

locals {
  tags = {
    "managed_by" = "eshgham-cron-deployer"
    "project"    = "eshgham-cron"
  }
  aws_region = "us-east-1"
  github_repository = "omsf-eco-infra/eshgham-cron-deploy"
}

module "deploy_bootstrap" {
  source = "/Users/dwhs/Dropbox/omsf/eco-infra/src/eshgham-cron/bootstrap-deploy-repo"

  github_repository = local.github_repository
  gh_token          = var.gh_token
  tags              = local.tags

  # role_name                = "eshgham-cron-github-deployer"
  # role_description         = "Role assumed by GitHub Actions to deploy ESHGHAM-cron modules."
  # max_session_duration     = 3600
  # github_oidc_provider_arn = null  # defaults to current account's provider
  # github_ref               = "refs/heads/main"
  # github_workflow_filename = "deploy.yaml"
  # github_audience          = "sts.amazonaws.com"
  # github_actions_secrets   = {}
  # extra_permission_sets    = []
  # additional_policy_arns   = []
}

module "terraform_backend_access" {
  source = "/Users/dwhs/Dropbox/omsf/eco-infra/src/cloud-cron/modules/github-s3-tfstate-access"

  role_name         = module.deploy_bootstrap.role_name
  state_bucket      = var.state_bucket
  aws_region        = local.aws_region
  github_repository = local.github_repository
  tags              = local.tags
}
