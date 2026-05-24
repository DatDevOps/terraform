variable "region" {
  description = "AWS region for the primary account (where the VPC peering connection will be initiated)"
  type        = string
  default     = "us-west-2"
}

variable "primary_profile" {
  description = "AWS CLI profile name for the primary account"
  type        = string
  default     = "sopes-saloon"
}

variable "security_profile" {
  description = "AWS CLI profile name for the secondary account"
  type        = string
  default     = "security"
}

variable "cross_account_role_name" {
  description = "Name of the cross-account role to be assumed"
  type        = string
  default     = "S3BucketManagementRole"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_+=,.@-]*$", var.cross_account_role_name))
    error_message = "Role name must start with a letter and can contain alphanumeric characters and these special characters: _+=,.@-"
  }
}

variable "primary_user_name" {
  description = "Name of the existing IAM user in the primary account who will assume the cross-account role"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_+=,.@-]*$", var.primary_user_name))
    error_message = "User name must start with a letter and can contain alphanumeric characters and these special characters: _+=,.@-"
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "s3_prefix" {
  description = "Prefix for S3 bucket names to be managed with this role."
  type        = string
  default     = "sopes-saloon"

}
