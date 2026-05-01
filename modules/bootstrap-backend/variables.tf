variable "bucket_name" {
  description = "Name of the S3 bucket used for Terraform state."
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking."
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow Terraform to delete the state bucket even when it contains objects."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to backend resources."
  type        = map(string)
  default     = {}
}
