include "root" {
  path = find_in_parent_folders()
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../modules/lambda"
}

dependency "dynamodb" {
  config_path = "../dynamodb"

  mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = {
    table_arn  = "arn:aws:dynamodb:eu-north-1:000000000000:table/mock"
    table_name = "mock"
  }
}

inputs = {
  function_name      = local.env_config.locals.function_name
  zip_path           = local.env_config.locals.lambda_zip_path
  dynamodb_table_arn = dependency.dynamodb.outputs.table_arn
  table_name         = dependency.dynamodb.outputs.table_name
  log_retention_days = local.env_config.locals.log_retention_days
  memory_mb          = local.env_config.locals.memory_mb
  timeout_seconds    = local.env_config.locals.timeout_seconds
  tags               = local.env_config.locals.tags
}
