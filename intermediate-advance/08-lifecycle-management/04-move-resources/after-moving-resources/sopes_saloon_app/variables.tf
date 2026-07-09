variable "region" {
  description = "Region to deploy resources to."
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "Instance type for web server."
  type        = string
  default     = "t3.micro"
}

variable "public_subnet_ids" {
  description = "Subnet ID to use for EC2 instance."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for security group."
  type        = string
}