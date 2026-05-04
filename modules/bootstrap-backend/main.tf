resource "aws_s3_bucket" "state" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "tls_certificate" "gitlab" {
  url = "https://gitlab.com"
}

resource "aws_iam_openid_connect_provider" "gitlab" {
  url = "https://gitlab.com"

  client_id_list = [
    "https://gitlab.com",
  ]

  thumbprint_list = [
    for certificate in data.tls_certificate.gitlab.certificates : certificate.sha1_fingerprint
  ]

  tags = var.tags
}

data "aws_iam_policy_document" "gitlab_deployer_assume_role" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.gitlab.arn,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "gitlab.com:aud"
      values = [
        "https://gitlab.com",
      ]
    }

    condition {
      test     = "StringLike"
      variable = "gitlab.com:sub"
      values = [
        "project_path:${var.gitlab_project_path}:*",
      ]
    }
  }
}

resource "aws_iam_role" "dev_deployer" {
  name               = var.dev_deployer_role_name
  assume_role_policy = data.aws_iam_policy_document.gitlab_deployer_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role" "prod_deployer" {
  name               = var.prod_deployer_role_name
  assume_role_policy = data.aws_iam_policy_document.gitlab_deployer_assume_role.json
  tags               = var.tags
}

locals {
  deployer_targets = {
    dev = {
      role_name     = aws_iam_role.dev_deployer.name
      table_name    = "shortener-dev"
      function_name = "shortener-dev"
    }
    prod = {
      role_name     = aws_iam_role.prod_deployer.name
      table_name    = "shortener-prod"
      function_name = "shortener-prod"
    }
  }
}

data "aws_iam_policy_document" "gitlab_deployer" {
  for_each = local.deployer_targets

  statement {
    actions = [
      "sts:GetCallerIdentity",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.state.arn,
    ]
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.state.arn}/*",
    ]
  }

  statement {
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteItem",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:ListTagsOfResource",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateTable",
    ]

    resources = [
      aws_dynamodb_table.locks.arn,
      "arn:${data.aws_partition.current.partition}:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${each.value.table_name}",
    ]
  }

  statement {
    actions = [
      "lambda:AddPermission",
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:GetPolicy",
      "lambda:ListVersionsByFunction",
      "lambda:RemovePermission",
      "lambda:TagResource",
      "lambda:UntagResource",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${each.value.function_name}",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${each.value.function_name}",
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${each.value.function_name}:*",
    ]
  }

  statement {
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${each.value.function_name}-role",
    ]
  }

  statement {
    actions = [
      "apigateway:*",
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:apigateway:${data.aws_region.current.name}::/apis",
      "arn:${data.aws_partition.current.partition}:apigateway:${data.aws_region.current.name}::/apis/*",
    ]
  }
}

resource "aws_iam_role_policy" "gitlab_deployer" {
  for_each = local.deployer_targets

  name   = "serverless-shortener-${each.key}-deploy"
  role   = each.value.role_name
  policy = data.aws_iam_policy_document.gitlab_deployer[each.key].json
}
