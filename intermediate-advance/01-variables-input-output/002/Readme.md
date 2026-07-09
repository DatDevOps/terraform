# Copy the content of 01-variables-output/001 into 01-variables-output/002
# NB: This module is a continuation of module basic/03-input_output. Do well to read that b4 continuing

<!--02 Input Variable and Data Types -->

# Input Variable Syntax

These are the various variable syntax for this module:

   variable "name_label" {}


   variable "name_label" {
    type        = value
    description = "string"
    default     = value
   }

# practical samples of variables:

   variable "aws_region" {
    type        = string
    description = "Region to use for AWS resources"
    default     = "us-east-1"
   }


   variable "create_nat_gateway" {
    type        = bool
    description = "Whether to create a nat gateway"
   }


   variable "instance_count" {
    type        = number
    description = "Number of instances to create"
   }

   variable "allowed_ports" {
    type        = list(number)
    description = "list of ports to allow"
    default  = [443, 80]
   }

   variable "subnet_cidrs" {
    type        = map(list(string))
    description = "Subnet CIDR list by subnet name"
    default = {
      subnet1 = ["10.0.0.0/24"]
      subnet2 = ["10.0.0.1/24"]
    }
   }

   NB for tuple below: that 1st object passed will be a string, 2nd a list of numbers, and 3rd a bool.
   It must match in that sequence with no additional or missing argument

   variable "sg_config" {
    type        = tuple([string, list(number), bool])
    description = "Config data for a security group"
   }

   variable "vpc_config" {
      description = "Config data for a vpc deployment"
      type        = object({
         name                 = string
         subnets              = map(string)
         create_nat_gateway   = bool
      })
      default = {
         name               = "my-vpc"
         subnets            = { 
            public = "10.0.1.0/24" 
            private = "10.0.2.0/24" 
         }
         create_nat_gateway = true
      }
   }



# 'any type' data type
This is really not a data type but Terraform privides it anyway and used when 
   - When you don't know the variable type or structure ahead of time
   - Determined at runtime by Terraform
   - Avoid using 'any type', unless "passing the value directly to a resource without interacting with it content" - Hashicorp

# Null data type
- Absence of a value
- Arguments set to null are ignored
- Terraform then uses the default argument value

Example 1. The value of vpc_region will be 'us-east-1' because there is not default value and so the provider set region is used:

   variable "vpc_region" {
    description = "region used for vpc"
    type        = string
    nullable = true
   }

   variable "aws" {
    region = "us-east-1"
   }

   variable "aws_vpc" "main"{
      region = var.vpc_region
   }

Example 2. The user is here forced to provide a value for aws_region during deployment:

   variable "vpc_region" {
    description = "region used for vpc"
    type        = string
    nullable = false
   }

   variable "aws" {
    region = "us-east-1"
   }

   variable "aws_vpc" "main"{
      region = var.vpc_region
   }

# Plan and Apply
Use the above to refactor our configuration.

On the commandline, set an environment (must be prefixed like this TF_VAR_<VARIABLE_KEY>) variable to hold the value of the api_key using below

   $ export TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Linux] 
   
   OR

   $ $env:TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Windows]

Now run:

    $ terraform fmt -check

    $ terraform fmt 

    $ terraform fmt [nothing returned because files are well formatted]

    $ terraform validate  [if syntax and logic looks good like below, proceed]

        Success! The configuration is valid.

    $ terraform plan -out m2.tfplan

    $ terraform apply m2.tfplan

Lets show how to modify the infra using commandline variable

   $ terraform plan -var "instance_type=t3.nano" -out m1.tfplan   [overrides the value in terraform.tfvars. Should show the instance is modified not replaced] 

    $ terraform apply m2.tfplan      

Now delete all infrastructure created

    $ terraform destroy  [enter 'yes' when prompted]


