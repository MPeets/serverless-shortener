include "root" {
  path = find_in_parent_folders()
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../modules/api-gateway"
}

dependency "lambda" {
  config_path = "../lambda"
}

inputs = {
  api_name               = local.env_config.locals.api_name
  lambda_invoke_arn      = dependency.lambda.outputs.invoke_arn
  lambda_function_name   = dependency.lambda.outputs.function_name
  stage_name             = local.env_config.locals.stage_name
  throttling_burst_limit = local.env_config.locals.throttling_burst_limit
  throttling_rate_limit  = local.env_config.locals.throttling_rate_limit
}
