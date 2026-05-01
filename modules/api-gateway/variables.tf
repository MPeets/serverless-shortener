variable "api_name" {
  description = "Name of the API Gateway HTTP API."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function used by API Gateway."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function API Gateway can invoke."
  type        = string
}

variable "stage_name" {
  description = "Name of the API Gateway stage."
  type        = string
}

variable "throttling_burst_limit" {
  description = "Default burst limit for API Gateway route throttling."
  type        = number
}

variable "throttling_rate_limit" {
  description = "Default steady-state requests per second for API Gateway route throttling."
  type        = number
}
