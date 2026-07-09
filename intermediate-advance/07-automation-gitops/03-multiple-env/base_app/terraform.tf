terraform {
  required_version = ">= 1.15.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }

  # Uses contents from backends/*.hcl files where actual backend values are passed in via -backend-config during terraform init
  backend "s3" {}
}