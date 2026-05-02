include "root" {
  path = find_in_parent_folders()
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../modules/dynamodb"
}

inputs = {
  table_name = local.env_config.locals.table_name
  tags       = local.env_config.locals.tags
}
