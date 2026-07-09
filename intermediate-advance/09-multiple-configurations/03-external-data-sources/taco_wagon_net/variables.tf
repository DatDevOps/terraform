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

variable "availability_zones_count" {
  type        = number
  description = "Number of availability zones to use"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
