<!-- Terraform Providers -->
# Visit here to read about various provider docs and modules: https://registry.terraform.io/browse/providers

# AWS provider modules(under Overview) and resource definitions(under documentation) with Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest

# Execise module by Ned Bellavance repo: https://github.com/ned1313/Terraform-Providers


This is a continuation of the previous module. So copy the project 03-terraform-providers/003/base_app into current 004

    $ cp -R 03-terraform-providers/003/base_app 03-terraform-providers/004

<!-- Multiple acounts and assume role -->

# AWS Provider profiles

You can configure your provider to use multiple profiles. 
If you don't specify which profile to use, Teeraform will use your default profile in you profile configuration

    provider "aws" {
      region  = var.region
      profile = var.default_profile_name
    }

    #Alias for DR region
    provider "aws" {
      alias   = "dr"
      region  = var.dr_region
      profile = var.dr_profile_name
    }

To assume a role in an account, the role arn has to be passed

    provider "aws" {
      #default provider
    }

    #Alias for DR region
    provider "aws" {
      alias   = "dr"
      region  = var.dr_region
      profile = var.dr_profile_name

      assume_role {
        role_arn = var.dr_role_arn # role in the targeted account to be assumed
      }
    }

# Pratical

# NB: I did not deploy the resources in this module because I had only one account from PluralSight. 
# Try this in personal machine with the two profiles configured and role created in the other account that can be be assumed by the primary account

If you have two profiles configured on your machine, say my-sandbox and security (any other profile for another account that you might actually have configure) do the  below before proceeding.

OTHERWISE go straight to step 1 below if you already have a role arn configure in another account and passed the value in terraform.tfvars

          $ cd 03-terraform-providers/004/aws_setup 

          $ terraform fmt -check

          $ terraform fmt

          $ terraform validate

          $ terraform plan

          #note the cross_account_role_arn in terminal outputs and 
          #use in as the value for security_role_arn = "SET_WITH_VALUE" in root module terraform.tfvars

          $ terraform apply 



Step 1. In variable.tf in the root module add:

    variable "security_role_arn" {
      description = "The ARN of the IAM role to assume in the secondary AWS account for S3 bucket creation"
      type        = string
    }

Step 2. Add a new provider to use an assume role arn and deploy the security account. IOn the root module and in provider.tf add:

    provider "aws" {
      alias = "security"
      region = var.region
      assume_role {
        role_arn = var.security_role_arn
      }
    }

Step 3. In root module, add the module to create the vpc flow log bucket in main.tf

    module "prod_s3_bucket" {
      source               = "../vpc_flow_logs"
      vpc_id = module.prod_vpc.vpc_id
      naming_prefix = "sopes-saloon"
      iam_role_arn = var.security_role_arn
      bucket_id_suffix = random_string.bucket_suffix.result

      providers = {
        aws = aws.security
        aws.vpc_account = aws
      }
    }


Step 4. in terraform.tfvars add the arn value of the role to be assume:

    security_role_arn = "SET_WITH_VALUE"

Now:


    $ cd 03-terraform-providers/004/base_app

    $ terraform init [reinitialize because we added a new  vpc module in main.tf]

    $ terraform validate [proceed if successful]

    $ terraform fmt -check [check for badly formatted code]

    $ terraform fmt [formatted code]

    $ terraform fmt -check [there should be badly formatted code]

    $ terraform plan -out m4.tfplan 

    $ terraform apply m4.tfplan

    $ terraform destroy

You can add another module to create a vpc flow log bucket for the security account in another region
