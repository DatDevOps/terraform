<!-- Building a CICD Pipeline -->

# Terraform Automation Considerations
First of all, some files should not be checked into source control. Git uses the .gitignore file to exclude certain files and directories, 
and GitHub provides a terraform‑specific default that ignores things like the .terraform directory and terraform.tfstate. 

You should also exclude files containing sensitive data, such as perhaps your tfvars files. 
Another key file is the dependency lock file, which is .terraform.lock.hcl. This records the exact provider versions used during initialization. 
Checking this file into source control ensures consistent provider versions across machines and CI systems. 
If you choose to omit it, you're responsible for managing provider version drift yourself. Terraform downloads provider plugins during initialization. 

On build servers with persistent storage, you can speed this up by caching plugins locally, using the TF_PLUGIN_CACHE_DIR environment variable. 
Automation also requires credentials for remote state and providers. These are typically supplied through machine identity or dynamic credentials, although static credentials can be used in simpler setups. 

Terraform's output can be quite verbose, which can interfere with automation. 
Setting the TF_IN_AUTOMATION environment variable reduces interactive output and signals that Terraform is running without a human observer. 
You'll also need to decide on a deployment pattern, whether to save execution plans from CI or generate new ones during CD, 
whether you should require manual review before applying changes in lower environments, and whether to enable continuous deployment for non‑production environments. 

Finally, consider error handling and logging. When encountering an error in your run, should you continue the pipeline or cancel the run? 
Also, some platforms capture logs really well, while others may require you to explicitly configure logging destination and logging level. 
In an automation context, Terraform relies heavily on environment variables. 

    TF_IN_AUTOMATION = TRUE 

    TF_LOG = "INFO"

    TF_LOG_PROVIDER "ERROR" 

    TF_LOG_PATH = "FILE_PATH" 

    TF_INPUT = "FALSE"    =====> [TF_INPUT to false prevents Terraform from prompting for input and instead fails fast on missing values]

    TF_VAR_name = "VARIABLE_VALUE"

    TF_CLI_ARGS = "COMMAND_LINE_FLAGS"

# Practicals
- Create a CI workflow actions
    * verify formatting and syntax
    * Perform static checks
    * Generate and analyse plans
- Run all checks in parallel

# Practical sent up
The followig setup will be need to complete the practicals:
- a GitHub repo for the module with just module code
- S3 bucket for backend using the setup directory in project root
- AWS account credentials for cicd and terraform configuration stored as a secret in GH

The only thing missing for our sent up is thebackend S3 bucket
    
    $ cd d intermediate/automation-gitops/02-cicd   [move into current module directory]

    $ $ cp -R ../01-automation/base_app/ .          [copies completed configuration from 01-automation/base_app] 

Now I have added the configs to create a bucket in setup/create_backend_storage/main.tf

    $ cd ./setup/create_backend_storage

    $ terraform init

    $ terraform fmt

    $ terraform validate

    $ terraform plan -out s3-backend.tfplan

    $ terraform apply s3-backend.tfplan  [copy the bucket name and region from the terminal outputs]

        bucket_info = {
        "bucket" = "tw-terraform-state20260605230611342700000001"
        "region" = "us-east-1"
        }    

Setup is done!

Now copy the buckname and region as below and paste it as additions to the various envs in all the various stage files with .hcl extensions in backend directory

        bucket = "tw-terraform-state20260605230611342700000001"
        region = "us-east-1"

Have your AWS Key ID and AWS Secret Access Key handy

    - Go to GH
    - Create a repo for this module
    - Click repo settings and go to 'Secrets and variables'
    - Click on Secrets nad variables
    - Click on Actions
    - Click on the variable and click on New repository variable
    - Enter TF_VERSION (for terraform version) as variable name
    - Enter 1.15.0 as the value of the variable
