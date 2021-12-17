module "lambda_layer" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "${var.prefix}-${var.package_name}-dependency"
  description         = "${var.prefix}-${var.package_name} dependency layer"
  compatible_runtimes = ["python3.9"]

  source_path = [
  {
      path = "${path.module}"
    
    commands = [
        "cd `mktemp -d`",
        "mkdir python",
      "docker run --rm -v $(pwd):/build -w /build mlupin/docker-lambda:python3.9-build pip install ${var.install_dependencies ? "" : "--no-dependencies"} --target=./python ${var.package_name}",
      ":zip ./python"
    ]
  }]
  
  store_on_s3 = true
  s3_bucket   = var.bucket
  tags = var.tags
}