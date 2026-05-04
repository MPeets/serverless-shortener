output "bucket_name" {
  description = "Name of the Terraform state S3 bucket."
  value       = aws_s3_bucket.state.bucket
}

output "bucket_arn" {
  description = "ARN of the Terraform state S3 bucket."
  value       = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "Name of the Terraform state lock table."
  value       = aws_dynamodb_table.locks.name
}

output "lock_table_arn" {
  description = "ARN of the Terraform state lock table."
  value       = aws_dynamodb_table.locks.arn
}

output "gitlab_oidc_provider_arn" {
  description = "ARN of the GitLab OIDC identity provider."
  value       = aws_iam_openid_connect_provider.gitlab.arn
}

output "dev_deployer_role_arn" {
  description = "ARN of the IAM role GitLab CI assumes for dev deployments."
  value       = aws_iam_role.dev_deployer.arn
}

output "prod_deployer_role_arn" {
  description = "ARN of the IAM role GitLab CI assumes for prod deployments."
  value       = aws_iam_role.prod_deployer.arn
}
