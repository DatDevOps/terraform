
<!-- Terraform State Options -->

<!-- Terraform State backend Options -->
Terraform state can be saved anywhere you can save a JSON object.
Some options include:

- Local backend: i.e on a device which is stored in terraform.tfstate and as backup in terraform.tfstate.backup
- Remote backend
    - S3, Azure storage, Google cloud storage
    - HCL terraform and Consul

Some backend features includes these 2 important once below and aren't supported by all backends
- Locking: prevents two terraform resources from accessing state data at the same time
- Workspaces: using the same code to manage multiple environment at the same time
- Access control : determines who can access the state data
- Data encryption: ensures data is encrypted and sensitive data is expose in transist

<!-- Backend configuration syntax -->

    terraform {
        backend "backend_type"{
            IDENTIFIER = LITERAL_VALUE
        }
        ..
        ..
        ..
    }

1. Example of an AWS backend using S3 - complete configuration {not recommended}

    terraform {
        backend "s3"{
            bucket     = "globo-state-12345"
            key        = "dev/terraform.tfstate"  # does not allow to using the config for multiple environments
            region     = "us-east-1"              # this can be source using the methods below, config or cli variables                               
            access_key = "ahjdaabdklaldba"        # this can be source using the methods below, config or cli variables
            secret_key = "ajhakjabkabkabjabaada"  # this can be source using the methods below, config or cli variables        
        }
        ..
        ..
        ..
    }

2. Example of an AWS backend using S3 - partial configuration

    terraform {
        backend "s3"{}
        ..
        ..
        ..
    }

    With partial configuration we can pass the other configuration durin initialization using any of the methods below:
    
    # using in line settings
    $ terraform init -backend-config="bucket=globo-state-12345"    


    # using a backend config file
    $ terraform init -backend-config="backend-settings.txt"    

<!-- State manupulation -->

There are 3 block types that allow you to manipulate the state data

1. Moved Block (moved.tf): Will moved a resource from one identifier to another. Useful when you are refactoring code

    moved{
        from = ADDRESS
        to   = ADDRESS
    }

2. Import Block(imports.tf): Use to move unmanaged resources into a configuration
    
    import{
        to   = ADDRESS
        id = "UNIQUE_IDENTIFIER"
    }

3. Remove Block(removed.tf): Allows you to remove a resource from state without destroying it
    
    removed{
        from = ADDRESS
        lifecycle{
            prevent_destroy = false
        }
    }

Each of this block uses the standard Terraform workflow of 'terraform plan' and 'terraform apply' allowing changes to state to be predictable and consistent

<!-- Terraform state inspection -->

The following command provides information about the state of a resource/s

    $ terraform show  [displays all state data]

    $ terraform state list [list all resources and data sources]

    $ terraform state show ADDR [lists all attributes of a single object. see example below]
    
    $ terraform state show aws_vpc.main [lists all attributes of a single object - aws_vpc_main]

    $ terraform show  [displays all state data]

    $ terraform show -json  [displays all state data in JSON]

Note that although ouputs of your configuration are stored in state, the are not included in the 'terraform show' command.
To access output state, use the terraform output commands

    $ terraform output [shows all state  stored outputs]

    $ terraform output -json [shows all state  stored outputs in JSON]

    $ terraform output <name_of_output> [shows a specific output stored in state ]

    $ terraform output -raw <name_of_output> [shows a specific output stored in state with quotation marks ]

    $ terraform state pull  [sends raw state to standard out - terminal]

Pulling and Pushing state data around:    

    $ terraform state pull > local.tfstate  [sends raw state to the file local.tfstate]

    $ terraform state push  <path_to_remote_location> [sends raw state to a remote path location]

Soon to be deprecated mv and rm commands:

    $ terraform state mv <SOURCE> <DESTINATION>  [moves a resource to a new address]

    $ terraform state rm ADDR [removes a resource from state]

Managing state synchronization and drift detection using state refresh using '-refresh-only'
Below are some kind of drift and informs the decision to use or not use the '-refresh-only' options
- Approved drift: made outside the code and approved (you  want to keep this change)
- Unauthorized drift: made outside the code and unapproved (use 'terraform plan' and terraform apply' to revert changes)
- Continual drift: made by a service you permitted (ignore the change)

<!-- State migration to remote backend - S3 -->

Here we now move away from  using local state to a remote backend on AWS S3. The requirements are as follows:
- Use S3 bucket provided by Ops team
- Migrate existing state
- Use partial configuration to the backend

# Create backend
Now lets create the S3 bucket:

    $ cd 06-terraform-state/s3_bucket_create/

    $ terraform init

    $ terraform fmt -check
    
    $ terraform fmt

    $ terraform validate

    $ terraform plan -out s3.tfplan

    $ terraform apply s3.tfplan  [copy bucket name and region from output]

Once successful try the state comamnds:

    $ terraform show 

        # aws_s3_bucket.taco_wagon:
        resource "aws_s3_bucket" "taco_wagon" {
            acceleration_status         = null
            arn                         = "arn:aws:s3:::taco-wagon20260508185949652100000001"
            bucket                      = "taco-wagon20260508185949652100000001"
            bucket_domain_name          = "taco-wagon20260508185949652100000001.s3.amazonaws.com"
            ....
            ...
        }

    $ terraform state list 

        aws_s3_bucket.taco_wagon
        aws_s3_bucket_public_access_block.taco_wagon_pab
        aws_s3_bucket_server_side_encryption_configuration.taco_wagon_encryption
        aws_s3_bucket_versioning.taco_wagon_versioning

    $ terraform state show aws_s3_bucket.taco_wagon

        # aws_s3_bucket.taco_wagon:
        resource "aws_s3_bucket" "taco_wagon" {
            acceleration_status         = null
            arn                         = "arn:aws:s3:::taco-wagon20260508185949652100000001"
            bucket                      = "taco-wagon20260508185949652100000001"
            bucket_domain_name          = "taco-wagon20260508185949652100000001.s3.amazonaws.com"
            bucket_prefix               = "taco-wagon"
            bucket_regional_domain_name = "taco-wagon20260508185949652100000001.s3.us-east-1.amazonaws.com"
            force_destroy               = true
            ...
            ...
        }

# Migrate from local to remote S3 backend

    $ cd 06-terraform-state/globo-webapp/

    $ terraform fmt -check

    $ terraform fmt 

    $ terraform validate

    #copies our local state file, terraform.tfstate, to out remote backend and saves it with under the key 'dev.tfstate'
    # By using partial config, as below, and passing the key or other configs, we can use the same configurtion for various ennvironments
    # If you did not destroy your infra and state file not empty, it will become empty after the initialization. It will also prompt you to accept
    # backend initialization

    $ terraform init -backend-config="key=dev.tfstate" [local state file,  terraform.tfstate, should now be empty and 'terraform show' still works]

    $ terraform plan -out newbackend.tfplan
    
    $ terraform apply newbackend.tfplan

Clicked on the EC2 output link in the terminal to access it and the webpage. 
Go to the S3 bucket on the AWS console to see your state under the prefix "dev.tfstate"
Now run the 'show' and list command to show that although the local terraform.tfstate is empty, you cna still access the remote state

    $ terraform show

    $ terraform state list

Now delete all resources

    $ terraform destroy  [enter 'yes' when prompted]    