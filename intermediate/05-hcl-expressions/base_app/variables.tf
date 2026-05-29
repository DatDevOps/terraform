variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "company" {
  description = "Name of the company"
  type =  string
}

variable "environment" {
  description = "Environment name (e.g., development, staging, production)"
  type        = string
  default     = "development"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for subnets."
  type = list(string)
  default = [ "10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24" ]
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = null
}

variable "team" {
  description = "Team responsible for the resources"
  type        = string
  default     = "Platform"
}
