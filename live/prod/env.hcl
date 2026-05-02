locals {
  env_name   = "prod"
  aws_region = "eu-north-1"

  table_name_prefix = "shortener-prod"
  table_name        = "shortener-prod"
  function_name     = "shortener-prod"
  api_name          = "shortener-prod"
  stage_name        = "$default"

  lambda_zip_path = "${get_terragrunt_dir()}/../../app/function.zip"

  log_retention_days     = 30
  memory_mb              = 256
  timeout_seconds        = 10
  throttling_burst_limit = 2
  throttling_rate_limit  = 1

  tags = {
    Env = "prod"
  }
}
