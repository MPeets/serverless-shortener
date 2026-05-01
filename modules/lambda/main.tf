data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "function" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.function.arn}:*"]
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]

    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_cloudwatch_log_group" "function" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_iam_role" "function" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "function" {
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.function.id
  policy = data.aws_iam_policy_document.function.json
}

resource "aws_lambda_function" "function" {
  function_name    = var.function_name
  role             = aws_iam_role.function.arn
  filename         = var.zip_path
  source_code_hash = filebase64sha256(var.zip_path)
  handler          = var.handler
  runtime          = var.runtime
  memory_size      = var.memory_mb
  timeout          = var.timeout_seconds
  tags             = var.tags

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.function,
    aws_iam_role_policy.function,
  ]
}
