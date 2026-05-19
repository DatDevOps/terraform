 <!-- Terraform state Backends -->
# NB
 Make sure to complete this module in one sitting if using PluralSight because if you dont and PluralSight provisions a new account for it might do so with a new account number and you will get this error when your get to practical-2:

    │ Error: reading Secrets Manager Secret (arn:aws:secretsmanager:us-east-1:329482598717:secret:burrito-barn-dev-api-key-GMOV2I): operation error Secrets Manager: DescribeSecret, https response error StatusCode: 400, RequestID: 59d39fdd-7687-4381-94a9-78f87fceb603, api error AccessDeniedException: User: arn:aws:iam::654654598709:user/cloud_user is not authorized to perform: secretsmanager:DescribeSecret on resource: arn:aws:secretsmanager:us-east-1:329482598717:secret:burrito-barn-dev-api-key-GMOV2I because no resource-based policy allows the secretsmanager:DescribeSecret action
    │ 
    │   with aws_secretsmanager_secret.api_secret,
    │   on main.tf line 109, in resource "aws_secretsmanager_secret" "api_secret":
    │  109: resource "aws_secretsmanager_secret" "api_secret" {
        ...
    }

Note the account number above was different from my new account


Now:
- Copy the content of /01-variables-input-output/004/base_app to /terraform/intermediate/02-terraform-state/02-state-backends
- Now delete the m4.tfplan file

# Terraform local backend
Most of the  modules exercise so far having been using terraform local backends because we did not specify a remote backend
- Local backend is the default backend to store state data
- Uses the configuration directory, terraform.tfstate
- Stored on local machine with potential loss of data and no remote access


# Terraform remote backend
The following is a remote backend that can be used:
- AWS S3
- Azure Blob Storage
- Google cloud storage
- HCP Terraform
 
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

<!-- Migrating state data -->
Following the following steps to migrate state data from one backend, including local backend, to another
- Backup state data
- Update backend configurations
- Run 'terraform init' which prompts you to accept the migration. Enter 'yes'

<!-- State migration to remote backend - S3 -->

Here we now move away from  using local state to a remote backend on AWS S3. The requirements are as follows:
- Use S3 bucket provided by Ops team
- Migrate existing state
- Use partial configuration to the backend


# Create backend
Now lets create the S3 bucket (creates an s3 bucketthat is private with versioning and server-side encryption enabled, and should have a policy attached to allow only authorized access):

    $ cd intermediate/02-terraform-state/02-state-backends/s3_bucket_create

    $ terraform init

    $ terraform fmt -check
    
    $ terraform fmt

    $ terraform validate

    $ terraform plan -out s3.tfplan

    $ terraform apply s3.tfplan  [copy bucket name and region from output]

# Migrate from local to remote S3 backend

    $ cd intermediate/02-terraform-state/02-state-backends/base_app

create a new file s3.tfbackend and add the content of the output above

    bucket = "taco-wagon20260519005246421800000001"
    region = "us-east-1"

Next add this block of code to your terraform.tf file

    terraform {
        ...
        ...
        backend "s3" {
            key    = "nacho_brigade/terraform.tfstate" 
            use_lockfile = true
            profile = "my-sandbox"
        }  
    }


'use_lockfile = true': Enables state locking. This prevents:

    - Two Terraform runs modifying state at the same time
    - Corruption / race conditions    

Now initialize the base_app project

    [might prompt you to enter 'yes' if there is pre-existing state data. Otherwise it will not.]
    $ terraform init --backend-config="s3.tfbackend" [copies existing state data, if exist, to remote backend]

    $ terraform fmt -check
    
    $ terraform fmt

    $ terraform validate

    $ terraform plan -out s3-remote.tfplan [enter secret 'value' when prompted]

    $ terraform apply s3-remote.tfplan  [copy bucket name and region from output]

Your local state file should be empty without state data. But 'terraform show' still returns state data from remote backend

    $ terraform show [returns state data from remote backend]


<!-- Terraform state locking -->
Prevents multiple users from making chnages to state at the same time. Terraform plan, apply, and console all place a lock on state.
If Terraform cannot acquire a lock on state, it usiually error out with a lock error that includes when the lock was placed and who placed it
In the event that a terraform process crashes and did not remove the lock, you can forcefully remove the lock using below:

    $ terraform force-unlock <LOCK_ID_FROM_LOCK_ERROR>

Do the  above with caution because state data might become unstable and you might need to recover from a previous version - thanks to s3 versioning

<!-- Testing Terraform state locking -->
Open  2 terminal in base_app

    - In terminal 1, run:

    $ terraform console   [opens terraform interactive shell which locks state]

    - In terminal 2, run:

    $ terraform apply s3.tfplan [ should throw error]

    │ Error: Error acquiring the state lock
    │ 
    │ Error message: operation error S3: PutObject, https response error StatusCode: 412, RequestID: PW3WW9XJ65EZQPB2, HostID: up0XHFfIx0AlCOo7RvT99mOYq1GSEHBK4iRxx9B1poOmrnFm1HVkBdKr/DQFXG7cGKcRBvNtw78=,
    │ api error PreconditionFailed: At least one of the pre-conditions you specified did not hold
    │ Lock Info:
    │   ID:        c562415b-514a-d7b3-e3b9-34931eda9f1f
    │   Path:      taco-wagon20260519005246421800000001/nacho_brigade/terraform.tfstate
    │   Operation: OperationTypePlan
    │   Who:       cogu@ip-172-19-160-197.ca-central-1.compute.internal
    │   Version:   1.15.3
    │   Created:   2026-05-19 01:46:58.492593304 +0000 UTC
    │   Info:      
    │ 
    │ 
    │ Terraform acquires a state lock to protect the state from being written
    │ by multiple users at the same time. Please resolve the issue above and try
    │ again. For most commands, you can disable locking with the "-lock=false"
    │ flag, but this is not recommended.    


To force unlock, do:

    $ terraform force-unlock c562415b-514a-d7b3-e3b9-34931eda9f1f [removes lock successfully and the .lock file]

    Do you really want to force-unlock?
    Terraform will remove the lock on the remote state.
    This will allow local Terraform commands to modify this state, even though it
    may still be in use. Only 'yes' will be accepted to confirm.

    Enter a value: shshshshshhs

    force-unlock cancelled.

Now on terminal 1:

    > exit [throws error because it could not longer find the .lock and thought it still had a lock on state. Very dangerous and throws the error below]

<!-- Terraform workspaces -->
- Supports multiple environment
- Single root module
- Seperate state data instances
- Shared backend
- When you initialize a root module, you create a default workspace
   - Default workspaces cannot be deleted
   - Terraform is aware of the current selected workspace and cn be reference with 'terraform.workspace' expression




Now delete all resources

    $ terraform destroy  [enter 'yes' when prompted]    