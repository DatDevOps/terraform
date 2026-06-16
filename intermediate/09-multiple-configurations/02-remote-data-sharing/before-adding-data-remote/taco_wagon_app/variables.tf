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

variable "vpc_id" {
  type        = string
  description = "VPC ID to use for security group"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs to use for instances"
}
