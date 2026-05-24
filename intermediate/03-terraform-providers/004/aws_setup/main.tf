# Configure the AWS Provider for both accounts
provider "aws" {
  alias   = "primary"
  profile = var.primary_profile
  region  = var.region

  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias   = "secondary"
  profile = var.security_profile
  region  = var.region

  default_tags {
    tags = var.tags
  }
}

# Data sources to get current account information
data "aws_caller_identity" "primary" {
  provider = aws.primary
}

data "aws_caller_identity" "secondary" {
  provider = aws.secondary
}