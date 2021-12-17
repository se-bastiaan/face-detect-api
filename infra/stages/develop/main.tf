terraform {
  required_version = ">=1.1.1"

  required_providers {
    aws = ">= 3.70.0"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "face_detect_api" {
  source = "../../modules/face-detect-api"
  stage  = "develop"
  tags   = var.aws_tags
  domain_name = var.domain_name
  prefix = var.prefix
}