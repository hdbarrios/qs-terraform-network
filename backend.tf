terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.12"
    }
  }

  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "qs-terraform-states"
    key            = "aws-networks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-networks-locks"
    encrypt        = false
    profile        = "qs-terraform"
  }
}

