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

  mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = {
    function_name = "mock"
    invoke_arn    = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-north-1:000000000000:function:mock/invocations"
  }
}

inputs = {
  api_name               = local.env_config.locals.api_name
  lambda_invoke_arn      = dependency.lambda.outputs.invoke_arn
  lambda_function_name   = dependency.lambda.outputs.function_name
  stage_name             = local.env_config.locals.stage_name
  throttling_burst_limit = local.env_config.locals.throttling_burst_limit
  throttling_rate_limit  = local.env_config.locals.throttling_rate_limit
}
