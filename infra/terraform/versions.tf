terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Phase 2.1: Remote backend. bucket/region/dynamodb_table via -backend-config=env/backend-dev.hcl
  backend "s3" {
    key = "cloud-only/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}
