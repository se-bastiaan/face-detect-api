resource "aws_s3_bucket" "deploy" {
  bucket        = "${var.prefix}-terraform-lambda-deploys"
  acl           = "private"
  force_destroy = "true"
  tags = var.tags

  lifecycle_rule {
    id      = "expiration"
    enabled = true

    tags = var.tags

    expiration {
      days = 1
    }
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "${var.prefix}-auth-api"

  tags = var.tags
}

module "face_recognition_dependency" {
  source     = "./modules/lambda-dependency-layer"
  package_name = "face-recognition"
  install_dependencies = true
  bucket = aws_s3_bucket.deploy.bucket
  tags = var.tags
  prefix = var.prefix
}

module "face_recognition_function" {
  name = "face-recognition"
  source     = "./modules/lambda-function"
  layers = [module.face_recognition_dependency.layer_arn]
  bucket = aws_s3_bucket.deploy.bucket
  api_gateway_arn = module.api_gateway.apigatewayv2_api_execution_arn
  tags = var.tags
  prefix = var.prefix
  memory_size = 1024
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${var.prefix}-gateway"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "cookie", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  create_api_domain_name = var.domain_name != null
  domain_name                 = var.domain_name != null ? "${var.prefix}.${var.domain_name}" : null
  # domain_name_certificate_arn = var.domain_name ? module.acm.this_acm_certificate_arn : null

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.logs.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - $context.requestTime - $context.routeKey $context.protocol - $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  integrations = {
    "$default" = {
      lambda_arn             = module.face_recognition_function.function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }
  }

  tags = var.tags
}
