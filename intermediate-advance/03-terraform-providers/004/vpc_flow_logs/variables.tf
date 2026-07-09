variable "vpc_id" {
  description = "The VPC ID to enable flow logs for"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]{8,17}$", var.vpc_id))
    error_message = "VPC ID must be in the format vpc-xxxxxxxx."
  }
}

variable "naming_prefix" {
  description = "Prefix to use for naming resources (will be used for S3 bucket and flow logs)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.naming_prefix)) && length(var.naming_prefix) >= 3 && length(var.naming_prefix) <= 30
    error_message = "Naming prefix must be 3-30 characters long, start and end with alphanumeric characters, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "bucket_id_suffix" {
  description = "Suffix to append to the S3 bucket name for uniqueness"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,63}$", var.bucket_id_suffix))
    error_message = "Bucket ID suffix must be 3-63 characters long and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "traffic_type" {
  description = "The type of traffic to capture (ALL, ACCEPT, or REJECT)"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "ACCEPT", "REJECT"], var.traffic_type)
    error_message = "Traffic type must be one of: ALL, ACCEPT, REJECT."
  }
}

variable "s3_bucket_force_destroy" {
  description = "Allow deletion of S3 bucket even if it contains objects (useful for testing)"
  type        = bool
  default     = true
}

variable "flow_log_format" {
  description = "The format for the flow logs (default AWS format or custom)"
  type        = string
  default     = null

  validation {
    condition     = var.flow_log_format == null || can(regex("\\$\\{[a-z-]+\\}", var.flow_log_format))
    error_message = "Flow log format must contain valid field references like $${srcaddr}, $${dstaddr}, etc."
  }
}

variable "max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated (60 or 600 seconds)"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.max_aggregation_interval)
    error_message = "Max aggregation interval must be either 60 or 600 seconds."
  }
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "The KMS key ID to use for S3 bucket encryption (optional)"
  type        = string
  default     = null
}

variable "source_account_id" {
  description = "The AWS account ID where the VPC resides (if different from the account deploying this module)"
  type        = string
  default     = null
}

variable "iam_role_arn" {
  description = "The ARN of an existing IAM role to use for the bucket creation and management. Will be used for tagging."
  type        = string
}
