variable "profile" {
  type        = string
  description = "AWS CLI profile to use for authentication"
  default     = "my-sandbox"
}

variable "company_name" {
  type        = string
  description = "Company name for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region for resource deployment"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the web server"
  default     = "t3.micro"
}

variable "network_bucket_config" {
  description = "Config for the network state bucket"
  type = object({
    bucket = string
    region = string
    key    = string
    profile = string
  })
}
