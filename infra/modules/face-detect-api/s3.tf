resource "aws_s3_bucket" "deploy" {
  bucket        = "${var.prefix}-terraform-lambda-deploys"
  acl           = "private"
  force_destroy = "true"
  tags          = var.tags

  lifecycle_rule {
    id      = "expiration"
    enabled = true

    tags = var.tags

    expiration {
      days = 1
    }
  }
}