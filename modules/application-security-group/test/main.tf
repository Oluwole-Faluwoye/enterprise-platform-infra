terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "application_security_group" {
  source = "./.."

  project          = "enterprise-platform"
  environment      = "dev"
  application_name = "payment-service"

  vpc_id = "vpc-00000000000000000"

  tags = {
    Team = "payments"
  }
}