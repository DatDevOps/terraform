terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "taco-wagon20260508193039560000000001"
    # key    = "globomantics/webapp/terraform.tfstate" # does not allow to using the config for multiple environments
    region  = "us-east-1"
    profile = "my-sandbox"
  }
}