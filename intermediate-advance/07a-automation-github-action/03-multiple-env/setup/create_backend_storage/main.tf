# Create S3 backend for Terraform state storage
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "my-sandbox"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "tw-terraform-state"

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_account_public_access_block" "terraform_state_public_access" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "bucket_info" {
  description = "Info to use for the Terraform S3 backend."
  value = {
    bucket = aws_s3_bucket.terraform_state.bucket
    region = aws_s3_bucket.terraform_state.region
  }
}