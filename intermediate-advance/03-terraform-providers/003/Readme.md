<!-- Terraform Providers -->
# Visit here to read about various provider docs and modules: https://registry.terraform.io/browse/providers

# AWS provider modules(under Overview) and resource definitions(under documentation) with Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest

# Execise module by Ned Bellavance repo: https://github.com/ned1313/Terraform-Providers

This is a continuation of the previous module. So copy the project 03-terraform-providers/002/base_app into current 003

    $ cp -R 03-terraform-providers/002/base_app 03-terraform-providers/003

<!-- Using Multiple Provider -->

# Multiple Provider Instances
  1. Administrative boundary: this boundary mans that the provider instances for aws, azure, and kubernetes 
    is limited to a single aws account, azure subscription ID, and kubernetes cluster respectively.

  2. Credential boundary: each provider instance can only support one set of credentials. If you need to have more than 
    one set of credetials, you will need to have more than one instance. AWS is limited to a single account, azure to a 
    single azure tenant and kubernetes to a single kubernetes cluster

# Provider Alias

Below is a configuration with multiple provide instances with aliases

main.tf

    provider "aws" {
      # Default provider. You can only have one default per provider
    }
      
    provider "aws" {
      # Unique Aliased  provider 1
      alias = "dr"
    }
      
    provider "aws" {
      # Unique Aliased  provider 2
      alias = "hub"
    }
      
    provider "aws" {
      # Unique Aliased  provider nth
      alias = "nth_name"
    }
      
Then for each resource you create, you can specify which provider alias to use in the root module.
If you don't specify the alias to use, Terraform will use the default alias instance

    provider "aws_vpc" "dr" {
      # Use "dr" instance
      provider = aws.dr
    }


How about specifying which alias a chils module should use? Well, that depends: See some examples below:

Example 1. Child module uses one provider

  - Child module in modules/vpc/main.tf where child resources are defined

        resource "aws_vpc" "main"{
          # ......
        }

  - Root/parent module where child is called in main.tf and stating specifically which provider alias to use. The default is used when none is specified    

        provider "aws" {}

        provider "aws" {
          # Aliased  provider
          alias = "dr"
        }

        module "dr_networking" {
          source = ".modules/vpc"
          provider = {
            provider = aws.dr
          }        
        }

Example 2. Child module uses multiple provider

  - Child module in modules/buckets/main.tf where child resources are defined
      terraform {
        required_providers{
          aws = {
            # you only use the configuration_aliases configuration 
            # if you plan to use multiple alias provider inside a child module
            configuration_aliases = [aws.alt]
          }
        }
      }

      resource "aws_s3_bucket" "main" {} # uses default provider instance

      resource "aws_s3_bucket" "alt"{
        provider = aws.alt
      }
      

  - Root/parent module where child is called in main.tf and stating specifically which provider aliases to pass. The default is used when none is specified

        provider "aws" {}

        provider "aws" {
          # Aliased  provider
          alias = "security"
        }

        module "buckets" {
          source = ".modules/buckets"
          provider = {
            aws = aws
            aws.alt = aws.security
          }        
        }

# Practicals
- config to support multi-region
- networking for DR in us-east-2
- use an aliased provider for the second region


1. In variable.tf add the region for the DR as shown below

    variable "dr_region" {
      default = "us-east-2"
    }


2. Create a dr.tf in the  root module and add the below content

    module "dr_vpc" {
      source      = "./modules/vpc"
      environment = var.environment
      region      = var.dr_region
      network_info = var.network_info

      # set the provider to use the DR region and alias defined in providers.tf
      providers = {
        aws = aws.dr   
        }
    }


3. And in provider.tf add teh alias provider as shown below

    #Alias for DR region
    provider "aws" {
      alias   = "dr"
      region  = var.dr_region
      profile = var.profile
    }

Now  run the below:

    $ cd 03-terraform-providers/003/base_app

    $ terraform init [reinitialize because we added a new module in dr.tf]

    $ terraform validate [proceed if successful]

    $ terraform fmt -check [check for badly formatted code]

    $ terraform fmt [formatted code]

    $ terraform fmt -check [there should be badly formatted code]

    $ terraform plan -out m3.tfplan [see the note below if you get EC2: DescribeAvailabilityZones error]

    $ terraform apply m3.tfplan

# NB you will get this error on PluralSight because of restricted permission for EC2 describe availability zone

  Error: fetching Availability Zones: operation error EC2: DescribeAvailabilityZones, https response error StatusCode: 403, RequestID: 066312fa-8b33-4955-9e51-2384c84c5ce8, api error UnauthorizedOperation: You are not authorized to perform this operation. User: arn:aws:iam::621120073967:user/cloud_user is not authorized to perform: ec2:DescribeAvailabilityZones with an explicit deny in a service control policy: arn:aws:organizations::674998908974:policy/o-yu55c2titn/service_control_policy/p-iq8d93ev
  │ 
  │   with module.dr_vpc.data.aws_availability_zones.available,
  │   on modules/vpc/main.tf line 1, in data "aws_availability_zones" "available":
  │    1: data "aws_availability_zones" "available" 


To fix this issue hard code the availability zones and remove the  block to get them dynamically in modules/vpc/main.tf. Save and run plan and apply  to deploy resources

# Remove

    # data "aws_availability_zones" "available" {
    #   state = "available"
    # }

    # locals {
    #   # map each subnet to an availability zone in a round-robin fashion
    #   subnet_to_az = {
    #     for subnet in keys(var.network_info.public_subnets) : 
    #       subnet => element(data.aws_availability_zones.available.names, index(keys(var.network_info.public_subnets), subnet) % length(data.aws_availability_zones.available.names))
    #   }
    # }

# Add the hardcoded values for both region with conditions as shown below and reference them

    locals {
      azs = ["us-east-1a", "us-east-1b", "us-east-1c"]

      subnet_to_az = {
        for subnet in keys(var.network_info.public_subnets) : 
          subnet => element(
            local.azs,
            index(keys(var.network_info.public_subnets), subnet) % length(local.azs)
          )
      }
    }


    locals {
      azs = var.region == "us-east-1" ? [
        "us-east-1a", "us-east-1b", "us-east-1c"
      ] : var.region == "us-west-2" ? [
        "us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"
      ] : []

      subnets = keys(var.network_info.public_subnets)

      subnet_to_az = {
        for idx, subnet in local.subnets :
        subnet => local.azs[idx % length(local.azs)]
      }
    }

Now deploy

    $ terraform plan -out m3.tfplan 

    $ terraform apply m3.tfplan

    $ terraform destroy
