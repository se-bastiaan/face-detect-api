terraform {
  required_version = ">=1.1.1"

  required_providers {
    aws = ">= 3.70.0"
  }

#   backend "s3" {
#     bucket  = "thalia-terraform-state"
#     key     = "concrexit/staging.tfstate"
#     region  = "eu-west-1"
#     profile = "thalia"
#   }
}

provider "aws" {
  region  = var.aws_region
}

module "face_detect_api" {
  source     = "../../modules/face-detect-api"
  stage      = "develop"
  tags = {
    "Terraform"   = true
  }
  domain           = var.domain_name
}