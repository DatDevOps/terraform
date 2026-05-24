terraform {
  required_version = ">= 1.11"
  # explicitly added provider requirements to ensure we use the correct version of the AWS provider
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  # another provider
    random = {
      source  = "hashicorp/random"
      version = "~>3.7.0"
    }  
  }
}