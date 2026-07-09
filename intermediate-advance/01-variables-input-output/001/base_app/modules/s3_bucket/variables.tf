variable "bucket_prefix" {
  description = "Prefix for S3 bucket name"
  type        = string
}

variable "ec2_instance_role_arn" {
  description = "The ARN of the EC2 instance role to allow access to the bucket"
}

