variable "profile" {
  description = "AWS CLI profile to use."
  default     = "my-sandbox"
  type        = string
}

# Actions in the PluralSight AWS cloud sandbox are restricted to us-east-1 and us-west-2 only.
variable "region" {
  default = "us-east-1"
}
variable "dr_region" {
  default = "us-west-2"
}

variable "environment" {
  default = "dev"
}

variable "instance_type" {
  description = "The EC2 instance type to use for the web server"
  type        = string
  default     = "t3.nano"
}

variable "network_info" {
  description = "A map of networking configuration values for the VPC and subnets"
  type = object({
    vpc_name             = string
    vpc_cidr             = string
    public_subnets       = map(string)
    map_public_ip        = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
  })
}
