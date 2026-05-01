# Terraform Backend Bootstrap

This module creates the shared remote-state resources used by Terraform or
Terragrunt:

- An S3 bucket for state files
- S3 bucket versioning, encryption, ownership controls, and public access block
- A DynamoDB table for state locking

Bootstrap is intentionally a two-step process. The backend resources cannot
store their own state in S3 until they already exist, so run this module once
with local state first.

## 1. Confirm AWS Profile

Use the project AWS profile and confirm the account before applying:

```bash
export AWS_PROFILE={your-user}
aws sts get-caller-identity
aws configure get region
```

## 2. Create a Temporary Bootstrap Root

Create a local-only Terraform root outside the module, for example
`bootstrap/main.tf`:

```hcl
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

module "backend" {
  source = "../modules/bootstrap-backend"

  bucket_name     = "serverless-shortener-terraform-state-497201305684"
  lock_table_name = "serverless-shortener-terraform-locks"

  tags = {
    Project   = "serverless-shortener"
    ManagedBy = "terraform"
  }
}
```

S3 bucket names are globally unique, so adjust `bucket_name` if AWS reports
that the name is already taken.

## 3. Apply Bootstrap

From the temporary bootstrap root:

```bash
terraform init
terraform plan
terraform apply
```

Record the outputs:

```bash
terraform output
```

## 4. Use the Remote Backend

After the bucket and lock table exist, configure future Terraform or Terragrunt
stacks to use them:

```hcl
backend "s3" {
  bucket         = "serverless-shortener-terraform-state-497201305684"
  key            = "dev/dynamodb/terraform.tfstate"
  region         = "eu-north-1"
  dynamodb_table = "serverless-shortener-terraform-locks"
  encrypt        = true
}
```

Use a different `key` per environment/component, for example:

- `dev/dynamodb/terraform.tfstate`
- `dev/lambda/terraform.tfstate`
- `dev/api-gateway/terraform.tfstate`

## Cleanup

Do not destroy the bootstrap resources while any Terraform state still lives in
the bucket. If this was only a test, empty the bucket first, then run:

```bash
terraform destroy
```
