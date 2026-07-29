variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "vpc_subnet_cidr" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "map_public_ip_on_launch" {
  description = "Whether to map public IPs on launch for the subnet"
  type        = bool
  default     = true
}

variable "http_port" {
  description = "The HTTP port for the application"
  type        = number
}

variable "ec2_instance_type" {
  description = "The type of EC2 instance to launch"
  type        = string
}



variable "company_name" {
  description = "The name of the company to which the resources belong"
  type        = string
  default     = "Globomantics"
}
variable "project" {
  description = "The name of the project to which the resources belong"
  type        = string
}
variable "environment" {
  description = "The environment in which the resources are deployed"
  type        = string
}
variable "billing_code" {
  description = "The billing code associated with the resources"
  type        = string
}

# Additional variables for testing other functions not used in this configuration
variable "instance_map" {
  description = "A map of instance names to their respective AMI IDs"
  type        = map(string)
  default     = { 
    "us-east-1" = "t2.micro"
    "us-west-2" = "t3.micro" 
  }
}

variable "subnet_cidrs" {
  description = "A list of CIDR blocks for subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "users" {
  description = "A list of users"
  type        = list(string)
  default     = ["alice", "bob"]
}

variable "json_string" {
  type    = string
  default = "{\"env\": \"production\", \"instance_count\": 3, \"enable_monitoring\": true}"
}
