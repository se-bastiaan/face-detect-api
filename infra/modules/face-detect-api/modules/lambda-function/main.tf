locals {
  root_directory = "${abspath(path.module)}/../../../../.."
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.prefix}-${var.name}"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  memory_size   = var.memory_size
  timeout       = var.timeout

  publish = true
  store_on_s3 = true
  s3_bucket   = var.bucket

  source_path = [
    {
      path = "${local.root_directory}/src/${var.name}-lambda"
      commands = [
        ":zip",
        "cd ${local.root_directory}",
        "mkdir ${local.root_directory}/${var.name}-lambda-reqs",
        "poetry export --format requirements.txt --without-hashes > ${local.root_directory}/${var.name}-lambda-reqs/requirements.txt",
        "cd ${local.root_directory}/${var.name}-lambda-reqs",
        "docker run --rm -v $(pwd):/build -w /build lambci/lambda:build-python3.8 pip install -r requirements.txt -t .",
        "rm requirements.txt",
        ":zip .",
        "rm -rf ${local.root_directory}/${var.name}-lambda-reqs",
      ],
      patterns = [
        "!poetry.lock",
        "!pyproject.toml",
        "!.venv/.*"
      ]
    }
  ]

  layers = var.layers

  attach_cloudwatch_logs_policy = true
  attach_policy_statements      = var.attach_policy_statements

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${var.api_gateway_arn}/*/*/*"
    },
    AllowExecutionFromAPIGatewayRoot = {
      service    = "apigateway"
      source_arn = "${var.api_gateway_arn}/*/*"
    }
  }

  policy_statements = var.policy_statements

  environment_variables = var.environment_variables
  tags                  = var.tags
}