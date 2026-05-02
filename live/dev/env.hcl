locals {
  env_name   = "dev"
  aws_region = "eu-north-1"

  table_name_prefix = "shortener-dev"
  table_name        = "shortener-dev"
  function_name     = "shortener-dev"
  api_name          = "shortener-dev"
  stage_name        = "$default"

  lambda_zip_path = "${get_terragrunt_dir()}/../../app/function.zip"

  log_retention_days     = 3
  memory_mb              = 128
  timeout_seconds        = 5
  throttling_burst_limit = 5
  throttling_rate_limit  = 2

  tags = {
    Env = "dev"
  }
}
