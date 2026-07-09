terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "my-sandbox"
}

locals {
  bucket_list = ["logs", "data", "backups"]
}
# locals {
#   bucket_list = ["logs","telemetry","data","backups"]
# }

resource "aws_s3_bucket" "use_count" {
  count         = length(local.bucket_list)
  bucket_prefix = local.bucket_list[count.index]
}