variable "profile" {
  type        = string
  description = "AWS CLI profile to use for authentication"
  default     = "my-sandbox"
}

variable "region" {
  description = "AWS Region for S3 bucket"
  type        = string
  default     = "us-east-1"
}