
# Terraform registry:  https://registry.terraform.io

# AWS Terraform registry:  https://registry.terraform.io/providers/hashicorp/aws/latest

# Terraform providers:  https://registry.terraform.io/namespaces/hashicorp


<!-- Terraform Modules -->
Terraform modules are file that contains terraform configurations or code
Terraform can have both a root module and a child module.

# Root and Child Modules
Difference between a Root Module and a Child module are:

        Root Module                     |      Child Module
1. You run terraform command here       |  Commands are executed through the root module
2. No parent module                     |  Invoked by by parent module
3. Outputs are stored in state          |  Outputs are exposed as attributes
4. Defines state backend                |  Inherits root module backend
5. Defines provider instances           |  Inherits provider instances {any provider definition throws a syntax error}

# Module purpose
- Logical grouping of reusable objects not neccesarily resources
- Enshrine best practices
- Create a layer of abstraction

# Module Types
- Resources modules: deploy a set of resources based on some common infrastructure pattern. 
  E.g. resources modules for setting up all the components needed for a functional AWSVPC or modules for deploying a Lambda function 
  with all the necessary IAM policies and an API gateway

- Data only modules: used to query information and are able to transform that information into a format required by a root module. 
  E.g. Imagine your organization has a catalog of approved AMIs. You could create a data‑only module that takes the OS type and required version 
  and returns the AMI ID matching those inputs and the current AWS region.

- Function modules: don't use resources or data sources. What they do is apply data transformation to the inputs supplied and return predictable, consistent outputs. 
  E.g. of this kind of module is the label module from CloudPosse or the naming module for Azure. Both take inputs like environment, project, owner, etc. and return back a consistent 
  naming convention for all the different resource types. Since you cannot write custom functions for Terraform, function modules are a way to add your own custom data transformation to a configuration.

# Module Block
The syntax for adding amodule is:

        module "module_name" {
                source = "literal_string" # value cannot contain variables and the only required value
                version = "version_contraint"

                # Meta arguments
                count = int # number of module instance to create
                for_each = map | set  #
                providers = {} # maps provider inheritance from parent to child module
                depends_on = []

                # module arguments. This are other arguments needed by the module
                ..
                ..
                
        }

# Module inputs and outputs       
1. Input variables: must have a value and you can make it optional by setting a default value

2. Output variables: are exposed as module attributes, supports all data types, and can be access in parant module
   using the syntax: module.module_name.output_name

# Module scoping
- Beyond input and output variables, everything else in the child module is can not be referenced

- Conversely, everything in the parent module except the provider instances can not be reference by a child module

- The only way a parent module can pass information to a child module is through the child module input variable values

- And the only way for a child module to pass information to a parent module is through it output variables values

# Module providers

<!-- Provider aliases -->
1. Single Provider instance: modules uses the default provider if no one is explicitly specified

  main.tf

      provider "aws" {
        # Default provider
      }

      module "networking" {
        source = "./module/vpc"
      }

  module/vpc/main.tf

      resource "aws_vpc" "main" {
        # Will use default provider because nothing specific was specified
      }

2. Multiple provider instance but module uses only the one specified alias

  main.tf

      provider "aws" {
        # Default provider
      }
      provider "aws" {
        alias = "dr"
      }
      provider "aws" {
        alias = "security"
      }

      module "networking" {
        source = "./module/vpc"
        provider ={
          aws = aws.security
        }
      }

  module/vpc/main.tf

      resource "aws_vpc" "main" {
        # Will use the security alias provider
      }

3. Multiple provider instance and module uses more than one alias

  main.tf

      provider "aws" {
        # Default provider
      }
      provider "aws" {
        alias = "dr"
      }
      provider "aws" {
        alias = "security"
      }

      #passed multiple aliases because the  moduleis configured to receive multiple provider aliases
      module "buckets" {
        source = "./module/buckets"
        provider ={
          aws = aws
          aws = aws.security
        }
      }

  module/buckets/main.tf

      #must use this syntax if you want to use multipl aliases in child modules
      terraform {
        required_providers{
          aws ={
            #thisis you specifying which resource block will use multiple alias block
            configuration_aliases = [aws.alt]
          }
        }
      }

      resource "aws_s3_bucket" "main" {} # Will use the default provider

      #The resource that will accept multiple aliases
      resource "aws_s3_bucket" "alt" {
        provider = aws.alt
      }

# Terraform module sources
1. Local file: here the source attribute receives the ralative path (recommended) or the absolute path. E.g. 

    source = "./modules/s3/"

2. Terraform registry

    source = "terraform-aws-modules/vpc/aws" # official terraform public registry

    source = "private.glomantics.xyz/terraform-aws-modules/vpc/aws" # private registry hosted by globomantics

3. Source control: Terraform supports GitHub, Git, BitBucket, or Mercurial. You can use query string to get a particular branch,
   hash, or tags. It  will download teh contents

    source = "github.com/globomantics/terraform-aws-vpc"

4. HTTP URL: It will download and extract the contents

    source = https://globomantics.xyz/modules/vpc-module.zip

5. Object storage: like AWS S3 bucket or GCS (Google Cloud Storage)    

The first two options are the most popular - local file and Terraform public registry
Modules cannot be cache or mirrored
 
# Practical (modularized VPC infra)
- improving the Terraform code being developed by the DevOps engineers in various business units
- The Taco Wagon team has come to you asking about potentially using modules in their code
- Switch to a public VPC Module
- Create a new module for Frontend

# Solution

- study the infra in /04-terraform-modules/base_app to see what it is like before we apply the above changes

- Now comment out the existing code in main-network.tf and add the below:

      # NETWORKING #
      module "vpc" {
        source  = "terraform-aws-modules/vpc/aws"
        version = "6.4.0"

        name                    = "${var.prefix}-vpc"
        cidr                    = var.vpc_address_range
        azs                     = slice(data.aws_availability_zones.available.names, 0, length(var.vpc_public_subnet_ranges))
        public_subnets          = var.vpc_public_subnet_ranges
        enable_nat_gateway      = false
        enable_vpn_gateway      = false
        enable_dns_hostnames    = true
        map_public_ip_on_launch = true
      }

    

Now run:

  $ terraform init [initialize the configuration and when you add a new module to configuration].

  $ terraform fmt [formats misformatted code]

  $ terraform validate [validates code for syntax error. This should fail]

Now in main-ec2.tf, replace these occurences with the following value:

  aws_vpc.main.id  ===> module.vpc.vpc_id

  [for subnet in aws_subnet.public_subnets : subnet.id]  ===> module.vpc.public_subnets

Now run again:

  $ terraform validate [This should pass now]  

  $ terraform plan -out m1.tfplan [This should pass now]  

  $ terraform apply m1.tfplan  

  $ terraform destroy [if you desire to deploy it. Otherwise skip]
