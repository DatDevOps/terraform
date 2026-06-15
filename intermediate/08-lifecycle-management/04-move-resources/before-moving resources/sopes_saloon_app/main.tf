provider "aws" {
  region = var.region
}

locals {
  naming_prefix = "sopes-saloon-${var.environment}-"
}