# You will need to initialize you backend with more information
terraform {
  backend "s3" {
    key = "eshgham-cron/terraform.tfstate"
  }
}

# This is a GitHub token that has permissions to read (and, ideally, write)
# GitHub Actions workflows for your account. This should not be hard coded
# in the repository; instead, make it available as an environment variable
# named TF_VAR_gh_token (possibly stored in GitHub Actions secrets)
variable "gh_token" {
  description = "GitHub PAT"
  type        = string
  sensitive   = true
}

# For simplicity, non-secret variables are hard coded here.
module "eshgham_cron" {
  source = "git::https://github.com/omsf-eco-infra/eshgham-cron.git"
  aws_region          = "us-east-1"
  schedule_expression = "cron(0 12 * * ? *)"
  eshgham_config_file = "./config.yaml"
  github_token        = var.gh_token
  email_sender        = "david.swenson@omsf.io"
  email_recipients = [
    "david.swenson@omsf.io",
  ]
  create_test_url   = true
  lambda_public_tag = "0.4.0"
}

output "scheduled_lambda_test_url" {
  value = module.eshgham_cron.scheduled_lambda_test_url
}

