provider "aws" {
  region = var.region

  # add default tags to all resources created by this provider
  default_tags {
    tags = {
      Project = "Base App"
    }
  }
}