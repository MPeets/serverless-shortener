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

variable "gitlab_project_path" {
  description = "GitLab namespace/project path allowed to assume deployer roles through OIDC."
  type        = string
  default     = "mihkelpeets65/serverless-shortener"
}

variable "dev_deployer_role_name" {
  description = "Name of the IAM role GitLab CI assumes for dev Terragrunt deployments."
  type        = string
  default     = "terragrunt-dev-deployer"
}

variable "prod_deployer_role_name" {
  description = "Name of the IAM role GitLab CI assumes for prod Terragrunt deployments."
  type        = string
  default     = "terragrunt-prod-deployer"
}
