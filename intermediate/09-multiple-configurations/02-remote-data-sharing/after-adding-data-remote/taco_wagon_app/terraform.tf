terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "tacowagon-app20260616003241917300000001"
    region       = "us-east-1"
    key          = "taco-wagon-app.tfstate"
    use_lockfile = true
    profile      = "my-sandbox"
  }
}
