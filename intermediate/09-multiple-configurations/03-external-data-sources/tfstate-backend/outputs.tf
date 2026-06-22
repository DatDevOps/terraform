output "app_bucket_config" {
  description = "State backend config for app bucket"
  value = {
    bucket = aws_s3_bucket.terraform_state["tacowagon-app"].bucket
    region = var.region
  }
}

output "net_bucket_config" {
  description = "State backend config for app bucket"
  value = {
    bucket = aws_s3_bucket.terraform_state["tacowagon-net"].bucket
    region = var.region
  }
}