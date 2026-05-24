# This Terraform configuration sets up a basic AWS infrastructure for a web application.
provider "aws" {
  region  = var.region
  profile = var.profile
}