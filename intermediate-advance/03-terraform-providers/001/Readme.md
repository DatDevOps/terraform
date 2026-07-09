<!-- Terraform Providers -->
# Visit here to read about various provider docs and modules: https://registry.terraform.io/browse/providers

# AWS provider modules(under Overview) and resource definitions(under documentation) with Terraform: https://registry.terraform.io/providers/hashicorp/aws/latest

# Execise module by Ned Bellavance repo: https://github.com/ned1313/Terraform-Providers

Copy the project code into 001 directory

  $ cp -R ./base_app ./001

Terraform comprises of:
- Terraform binary
- Configuration files
- State data
- Provider pluggin

This module deals with provider plugins and how it leverages them to manage the lifecycle of you resources.
A Terraform provider sits between Terraform and the Platform where your resourcs are provisioned.
It translate Terraform objects (resources, data sources) along with various actions (create, recreate, modify, and destroy) to
Platform APIs (network, storage, compute, IAM etc) and actions (create, update, read, or delete).
It works accord a plthora of platforms using the same construct

# Provider Sources
- Terraform public registry
- Privately hosted registry
- Local filesystem

# Provider Tiers
- Official : maintained by Hashicorp and in the 'hashicorp' namespace
- Partner: maintained by Hashicorp partners
- Community: maintained by the community

When you initialize a project the provider plugin is download to the .terraform folder

            ||
    Downloads provider plugin 
            ||
            \/
  HCL ===> init ===> .terraform


Once a project is initialized and plugins downloaded, they don't have to be downloaded again unless you want to chnage the version being used

# Implicit provider discovery in main.tf [not recommended approach]
When you initialize a project, terraform looks at the name in the  provider or begining of the resource block 
It then checks the public registry for the provider and if it finds one, it is downloaded into .terraform

  provider "aws" {}

  resource "aws_instance" "web" {}

# Explicit provider discovery in terrafor.tf [recommended approach]

  terraform{
    required_providers{
      local_name ={
        source = "namespace/type" # for public registry which is the default or below
        #source = "hostname/namespace/type" # for private registry or local filesystems
        version = "version_constraint # =, >, <, !=, ~>
        alias = "string_value" #allows you to create multiple instances of the same provider
      }
    }
  }

Once you set an alias for a provider, all other instances of the provider will require an alia too.
If an provider alis is not set, the provider alis is used as the default

The required block can be defined both in root and child modules can be different:

  In terraform.tf

      terraform{
        required_providers{
          aws ={
            source = "hashicorp/aws" 
            version = "6.12.0"
          }
        }
      }

  In module/child/versions.tf

      terraform{
        required_providers{
          random ={
            source = "hashicorp/random" 
            version = "~>3.0"
          }
        }
      }

once a project is initialized, all provider plugins, from root and child modules, are downloaded

Note that if you use imlicit provide discovery, terraform creates an instance of the provider implicitly and
most provider require certain configuration which you must supply, otherwise it throws an error. E.g:
- AWS provider [PROFILE, REGION is required]
- Azure provider [Subscription ID is required]
- Kubernetes [Hostname of the kubernetes cluster is required]


# Practicals
- Install a provider

    $ cd 03-terraform-providers/001/base_app [moved into project directory]

At this point we don't have a provider info but terraform can still initialize the project using Implicit Provider Discovery as long as you have the right AWS credentials or prole configured

    $ terraform init


But if you try to run 'Terraform Plan', it  will fail as it needs some provider information that are missing like:

    - │ Error: Error: Invalid provider configuration
    - │ Error: invalid AWS Region: none
    - │ Error: No valid credential sources found


Now add the missing provider configs:
1. create a provider.tf and add the below content. Not that you can add it to the top of main.tf file. But it could become meesy as the number of your provider grows. so seperatng themin providers.tf now makes sense

    provider "aws" {
      region  = var.region
      profile = var.profile
    }

2. In terraform.tf, add the low inside the block

    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
      }
    }

Now run plan. There should be no error

    $ terraform plan -out m1.tfplan

Apply if 'terraform plan' was successful and you wish to deploy the reesources

    $ terraform apply mt.tfplan  [deploys resources]

# Provider Commands

Make sure to be in the project directory initialized above if you have not done so

    $ cd 03-terraform-providers/001/base_app [moved into project directory]

    $ terraform version [shows the provider used and the version]

        Terraform v1.15.4
        on linux_amd64
        + provider registry.terraform.io/hashicorp/aws v6.46.0  

    $ terraform providers [shows the  list of prlovisers used in you configuration and the version constraints for both root and child modules]

        Providers required by configuration:
        .
        ├── provider[registry.terraform.io/hashicorp/aws] ~> 6.0
        └── module.prod_vpc
            └── provider[registry.terraform.io/hashicorp/aws]

        Providers required by state:

            provider[registry.terraform.io/hashicorp/aws]  


    $ terraform providers -h [ shows you your options you can use with 'terraform providers' command]

          referenced modules, as an aid to understanding why particular provider
          plugins are needed and why particular versions are selected.

        Options:

          -test-directory=path  Set the Terraform test directory, defaults to "tests".

          -var 'foo=bar'        Set a value for one of the input variables in the root
                                module of the configuration. Use this option more than
                                once to set more than one variable.

          -var-file=filename    Load variable values from the given file, in addition
                                to the default files terraform.tfvars and *.auto.tfvars.
                                Use this option more than once to include more than one
                                variables file.


        Subcommands:
            lock      Write out dependency locks for the configured providers
            mirror    Save local copies of all required provider plugins
            schema    Show schemas for the providers used in the configuration
                

    $ terraform providers schema -json [ returns a json object that can be parsed or passedto anothe program or LLM]

    
