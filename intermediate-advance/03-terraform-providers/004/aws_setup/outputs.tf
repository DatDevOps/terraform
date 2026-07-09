# Outputs for important resource information

output "s3_user_name" {
  description = "Name of the existing IAM user in the primary account"
  value       = data.aws_iam_user.existing_s3_user.user_name
}

output "s3_user_arn" {
  description = "ARN of the existing IAM user in the primary account"
  value       = data.aws_iam_user.existing_s3_user.arn
}

output "cross_account_role_name" {
  description = "Name of the cross-account role in the secondary account"
  value       = aws_iam_role.cross_account_s3_role.name
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account role in the secondary account"
  value       = aws_iam_role.cross_account_s3_role.arn
}

output "s3_bucket_policy_name" {
  description = "Name of the S3 bucket management policy"
  value       = aws_iam_policy.s3_bucket_permissions.name
}

output "s3_bucket_policy_arn" {
  description = "ARN of the S3 bucket management policy"
  value       = aws_iam_policy.s3_bucket_permissions.arn
}
