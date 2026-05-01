variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "zip_path" {
  description = "Path to the Lambda deployment zip file."
  type        = string
}

variable "handler" {
  description = "Lambda handler entry point."
  type        = string
  default     = "handler.handler"
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table the function can read and write."
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table passed to the function."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda CloudWatch logs."
  type        = number
  default     = 14
}

variable "memory_mb" {
  description = "Lambda function memory size in MB."
  type        = number
  default     = 128
}

variable "timeout_seconds" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to Lambda resources that support tagging."
  type        = map(string)
  default     = {}
}
