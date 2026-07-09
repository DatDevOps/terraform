output "s3_bucket_name" {
  description = "Name of the S3 bucket created for VPC flow logs"
  value       = aws_s3_bucket.vpc_flow_logs.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket created for VPC flow logs"
  value       = aws_s3_bucket.vpc_flow_logs.arn
}

output "flow_log_id" {
  description = "The Flow Log ID"
  value       = aws_flow_log.vpc_flow_logs.id
}

output "flow_log_arn" {
  description = "The ARN of the Flow Log"
  value       = aws_flow_log.vpc_flow_logs.arn
}
