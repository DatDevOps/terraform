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

variable "vpc_cidr_range" {
  description = "CIDR range for VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_ranges" {
  description = "CIDR ranges for subnets."
  type        = list(string)
  default     = ["10.0.0.0/24"]
}