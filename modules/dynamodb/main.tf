resource "aws_dynamodb_table" "short_links" {
  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = "slug"

  attribute {
    name = "slug"
    type = "S"
  }

  tags = var.tags
}
