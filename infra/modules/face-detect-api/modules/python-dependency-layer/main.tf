module "lambda_layer" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "${var.package_name}-dependency"
  description         = "${var.package_name} dependency layer"
  compatible_runtimes = ["python3.8"]

  source_path = [
  {
      path = "${path.module}"
    
    commands = [
        "cd `mktemp -d`",
        "mkdir python",
      "docker run --rm -v $(pwd):/build -w /build lambci/lambda:build-python3.8 pip install --no-dependencies --target=./python ${var.package_name}",
      ":zip ./python"
    ]
  }]
}