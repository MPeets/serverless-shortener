terraform {
  required_version = ">= 1.6.0"

  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

locals {
  name = "serverless-shortener-dev-sandbox"

  tags = {
    Project     = "serverless-shortener"
    Environment = "dev-sandbox"
    ManagedBy   = "terraform"
  }
}

module "dynamodb" {
  source = "../modules/dynamodb"

  table_name = local.name
  tags       = local.tags
}

module "lambda" {
  source = "../modules/lambda"

  function_name      = local.name
  zip_path           = "../app/function.zip"
  dynamodb_table_arn = module.dynamodb.table_arn
  table_name         = module.dynamodb.table_name
  log_retention_days = 3
  timeout_seconds    = 5
  memory_mb          = 128
  tags               = local.tags
}

module "api_gateway" {
  source = "../modules/api-gateway"

  api_name               = local.name
  lambda_invoke_arn      = module.lambda.invoke_arn
  lambda_function_name   = module.lambda.function_name
  stage_name             = "$default"
  throttling_burst_limit = 5
  throttling_rate_limit  = 2
}

output "api_endpoint" {
  value = module.api_gateway.api_endpoint
}
