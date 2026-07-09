terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "tacowagon-net20260616003241922400000002"
    region       = "us-east-1"
    key          = "taco-wagon-net.tfstate"
    use_lockfile = true
    profile      = "my-sandbox"
  }
}
