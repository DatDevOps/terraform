# -----------------------------------------------------------------------------
# Terraform State Backend Infrastructure
# -----------------------------------------------------------------------------
# This configuration creates the S3 buckets used to store Terraform state
# for the Taco Wagon configurations.
# -----------------------------------------------------------------------------

provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  bucket_prefixes = toset(["tacowagon-app", "tacowagon-net"])
}

# S3 Bucket for Terraform State
# Using bucket_prefix ensures a globally unique name
resource "aws_s3_bucket" "terraform_state" {
  for_each      = local.bucket_prefixes
  bucket_prefix = each.key
  force_destroy = true

  tags = {
    Name = "${each.key}-state"
  }
}

# Enable Versioning for State Recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  for_each = local.bucket_prefixes
  bucket   = aws_s3_bucket.terraform_state[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  for_each = local.bucket_prefixes
  bucket   = aws_s3_bucket.terraform_state[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block All Public Access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  for_each = local.bucket_prefixes
  bucket   = aws_s3_bucket.terraform_state[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
