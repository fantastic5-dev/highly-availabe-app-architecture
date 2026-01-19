terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  access_key = "AKIA2UC3ETLV2QIXHGGK"
  secret_key = "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"
}