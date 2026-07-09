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

# Changing from one remote s3 to another

    $ terraform init -reconfigure --backend-config="s3.tfbackend" 

    $ terraform init -migrate-state --backend-config="s3.tfbackend" 

Difference between the two terraform init commands
1. terraform init -reconfigure --backend-config="s3.tfbackend". Reinitializes the backend configuration. Ignores any saved backend settings from previous runs. Uses the backend config you provide now (s3.tfbackend).
   Does not automatically migrate existing state from one backend to another unless Terraform decides it is needed. 

2. terraform init -migrate-state --backend-config="s3.tfbackend". Also initializes with the backend config provided. If Terraform detects that the backend has changed, 
   it will migrate state from the current backend  to the new backend. Useful when switching to a different backend and you want Terraform to move the existing state.

Note: In newer Terraform versions, -migrate-state may be the default behavior when backend changes are detected, while -reconfigure is still useful for forcing backend re-read.

<!-- Short summary -->
-reconfigure: force re-read backend config and ignore stored backend settings.

-migrate-state: allow Terraform to move existing state to the new backend if the backend backend is changed.    


#  Terraform state locking
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

Now on terminal 2, go ahead and delete all the resources when you are ready:

    $ terraform destroy  [enter 'yes' when prompted] 

<!-- Terraform workspaces -->
# Merits of Terraform WorkSpaces includes:

- Supports multiple environment
- Single root module
- Seperate state data instances
- Shared backend
- When you initialize a root module, you create a default workspace
   - Default workspaces cannot be deleted
   - Terraform is aware of the current selected workspace and cn be reference with 'terraform.workspace' expression

# The challenges of Terraform Community WorkSpaces include:

- Shared backend: Anyone working in the workspace can see all state data and modify them for all environment. Something you may not want
- Code Changes and promotion: Community workspaces do not know about version control, which mean changes to an environment, say dev, will be applied to all all environments (stg, test, prod etc) if you do not specify the selected workspace
- Managing variables values: can quickly get messy and does not scale well

# Enterprise Terraform WorkSpaces include:
- HCP Terraform
- Terraform Enterprise

Enterprise Terraform Workspaces are fully featured and are core construct of the two enterprise workspaces above. 
We are focused on the community edition which amongs other things:
- lacks access control
- variable value management
- VCS (version control systems) integration

# Terraform workspace commands
- terraform workspace show: shows the selected workspace
- terraform workspace list: list all available workspace
- terraform workspace new <NEW_WORKSPACE_NAME>: creates a new workspace and select that workspace as the current context
- terraform workspace select <NEW_WORKSPACE_NAME>: changes the workspace context to the specified workspace name(selects the workspace)
  You can tell Terraform to switch to the named workspace and create it if it does not already exist: terraform workspace select -or-create=true <NEW_WORKSPACE_NAME>
- terraform workspace delete <NEW_WORKSPACE_NAME>: deletes a specified workspace along with its state data. By default terraform workspace delete does not delete
  state data with managed resources. But you can force delete it by passing the '-force' option/flag to delete it away


# Workspace practical
- Create and deploy a dev-2 environment
- Use terraform.workspace instead of var.environment

Make this changes in main.tf:
- Add a new local environment   = terraform.workspace == "default" ? var.environment : terraform.workspace

- In EC2 resource block "aws_instance", add this 'environment = local.environment' and remove 'environment = var.environment'

- Comment out the names and changes the names "aws_iam_instance_profile", "aws_iam_role", and "aws_secretsmanager_secret" reources to "${local.role_name}-${local.environment}"


Now run the following command:

    $ terraform workspace show [shows you are in the default workspace. This workspace cannot be deleted]
        default

    $ terraform plan -out s3-remote.tfplan [ should return no chnages if nothing has changed]

    $ terraform workspace new dev-2 [creates a new dev-2 workspace and select that workspace as the current context]

        Created and switched to workspace "dev-2"!

        You're now on a new, empty workspace. Workspaces isolate their state,
        so if you run "terraform plan" Terraform will not see any existing state
        for this configuration.

    $ terraform workspace show [shows the new workspace context] 

        dev-2  

    $ terraform workspace list [shows all the workspaces and the * indicates the selected/current workspace]

        default
        * dev-2  

    $ terraform state list [should return nothing as there are no managed object in this workspace]

    $ $ terraform plan -out s3-remote-dev-2.tfplan

    $ $ terraform apply s3-remote-dev-2.tfplan [enter yes if prompted to create resources in dev-2]

Now go to the AWS console and visit both instances created by the default and dev-2 workspaces. The former should have "dev" on the page and the latter "dev-2"

    $ terraform workspace list [shows all the workspaces and the * indicates the selected/current workspace]
        default
        * dev-2

Now to delete the dev-2 workspace when we are done, we need to delete the managed resources first. Can't delete a workspace with managed resources in state unless you use the '-force' flag/option

    $ terraform destroy -auto-approve [destroys all resource without prompting]

    $ terraform workspace select default [switch to a different workspace to delete your current workspace - dev. Can't delete current space, you must switch just like git]

    $ terraform workspace delete dev-2 [deletes the dev-2 workspace]

    $ $ terraform workspace list [dev-2 workspace deleted]
        * default

    $ $ terraform destroy -auto-approve [deletes all default workspace resources]

   