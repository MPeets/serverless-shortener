locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  env_name   = local.env_config.locals.env_name
  aws_region = local.env_config.locals.aws_region

  common_tags = merge(
    {
      Project     = "serverless-shortener"
      Environment = local.env_name
      ManagedBy   = "terragrunt"
    },
    local.env_config.locals.tags,
  )
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
terraform {
  backend "s3" {
    bucket         = "serverless-shortener-terraform-state-497201305684"
    key            = "${replace(path_relative_to_include(), "\\", "/")}/terraform.tfstate"
    region         = "${local.aws_region}"
    dynamodb_table = "serverless-shortener-terraform-locks"
    encrypt        = true
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}
