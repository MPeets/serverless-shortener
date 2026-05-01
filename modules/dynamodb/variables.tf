variable "table_name" {
  description = "Name of the DynamoDB table used to store shortened URLs."
  type        = string
}

variable "billing_mode" {
  description = "DynamoDB billing mode for the table."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be either PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "tags" {
  description = "Tags to apply to the DynamoDB table."
  type        = map(string)
  default     = {}
}
