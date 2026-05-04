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
