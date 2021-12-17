resource "aws_cloudwatch_log_group" "logs" {
  name = "${var.prefix}-gateway"

  tags = var.tags
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

  create_api_domain_name      = var.domain_name != null
  domain_name                 = var.domain_name != null ? "${var.prefix}.${var.domain_name}" : null
  domain_name_certificate_arn = var.domain_name != null ? module.acm.this_acm_certificate_arn : null

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.logs.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - $context.requestTime - $context.routeKey $context.protocol - $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  integrations = {
    "$default" = {
      integration_type    = "AWS_PROXY"
      integration_subtype = "StepFunctions-StartExecution"
      credentials_arn     = aws_iam_role.step_function_execution.arn

      # Note: jsonencode is used to pass argument as a string
      request_parameters = jsonencode({
        Input           = "$request.body",
        StateMachineArn = module.step_function.state_machine_arn
      })

      payload_format_version = "1.0"
      timeout_milliseconds   = 12000
    }
  }

  tags = var.tags
}

# Conditional ACM and DNS setup

data "aws_route53_zone" "this" {
  count = var.domain_name == null ? 0 : 1
  name  = var.domain_name
}

resource "aws_route53_record" "api" {
  count   = var.domain_name == null ? 0 : 1
  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = var.prefix
  type    = "A"

  alias {
    name                   = module.api_gateway.apigatewayv2_domain_name_configuration.0.target_domain_name
    zone_id                = module.api_gateway.apigatewayv2_domain_name_configuration.0.hosted_zone_id
    evaluate_target_health = false
  }
}

module "acm" {
  count   = var.domain_name == null ? 0 : 1
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 2.0"

  domain_name               = var.domain_name
  zone_id                   = data.aws_route53_zone.this[0].id
  subject_alternative_names = ["${var.prefix}.${var.domain_name}"]

  tags = var.tags
}