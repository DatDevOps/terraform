# Naming prefix for all resources created in this module
variable "naming_prefix" {
  description = "Prefix for naming resources."
  type        = string
}

# CIDR range for the VPC
variable "vpc_cidr_range" {
  description = "CIDR range for VPC."
  type        = string
}

# List of CIDR ranges for public subnets
variable "public_subnet_ranges" {
    description = "CIDR ranges for public subnets."
    type        = list(string)
}