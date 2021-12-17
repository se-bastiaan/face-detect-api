module "face_recognition_dependency" {
  source               = "./modules/lambda-dependency-layer"
  package_name         = "face-recognition"
  install_dependencies = true
  bucket               = aws_s3_bucket.deploy.bucket
  tags                 = var.tags
  prefix               = var.prefix
}

module "face_recognition_function" {
  name            = "face-recognition"
  source          = "./modules/lambda-function"
  layers          = [module.face_recognition_dependency.layer_arn]
  bucket          = aws_s3_bucket.deploy.bucket
  api_gateway_arn = module.api_gateway.apigatewayv2_api_execution_arn
  tags            = var.tags
  prefix          = var.prefix
  memory_size     = 1024
}