# This Terraform configuration sets up a basic AWS infrastructure for a web application.
# Defaults for the AWS provider are defined here, including the region and profile to use for authentication.
provider "aws" {
  region  = var.region
  profile = var.profile
}

#Alias for DR region
provider "aws" {
  alias   = "dr"
  region  = var.dr_region
  profile = var.profile
}

provider "aws" {
  alias  = "security"
  region = var.region
  assume_role {
    role_arn = var.security_role_arn
  }
}