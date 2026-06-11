# Copy the content of 01-variables-input-output/base_app into the 001 before continuing
# NB: This module is a continuation of module basic/03-input_output. Do well to read that b4 continuing

<!--01 Input Variable and Data Types -->

# Variable Syntax

These are the various variable syntax for this module:

   variable "name_label" {}


   variable "name_label" {
    type        = value
    description = "string"
    default     = value
   }

# practical sample of variables:

   variable "aws_region" {
    type        = string
    description = "Region to use for AWS resources"
    default     = "us-east-1"
   }

# Variable reference

    var.<name_label>

For example to get the aws region from the aws_region variable above we do:

    var.aws_ region    [value will be the default of 'us-east-1']

All variable can be set to a specific type with description. You can also set a default value for a variable
All variable value must be available during 'terraform plan', otherise terraform will prompt for it where there is no default set or use the default where one is set


<!-- Variable arguments -->
1. Sensitive variable arguments: A boolean value, true/false, and defaults to false.
   This flag tells Terraform to hide or not hide a value from output. Note that value can
   still be stored in a plain file and anyone with access can view it

2. Ephemeral variable arguments: A boolean value, true/false, and defaults to false.
   Note that value can never be stored in a plain file. It has limited use

3. Validation blocks: allows to test the value of a variable using conditional statements. If condition is not met, the supplied error is returned

   variable "aws_region" {
        type        = string
        description = "Region to use for AWS resources"
        default     = "us-east-1"

        validation{
            condition   = startswith("us-",var.aws_region)
            error_message = "Must use a US region."
        }
   }


4. Nullables: allows to set if a value can be null using a boolean of true/false


   variable "aws_region" {
        type        = string
        description = "Region to use for AWS resources"
        default     = "us-east-1"
        nullable = false
   }

# Pratical scenerio for Globomatics:
- Apply best practices for variables
- Add new input variables to make it more dynamically
- Update the S3 module to allow all EC2 instances to access it

Now that we have completed all of teh above request, lets us deploy the infrastructure.

Note tat you can pass variable using the commandline when you want to deploy the application

<!-- # Passing commandline argument during deploy -->

# -var option
You can pass commandline argument when running 'terraform plan'

   $ terraform plan -var "instance_type=t2.micro"

   $ terraform plan -var "instance_type=t2.micro" -var "aws_region=us-east-1"

# -var-file option

   $ terraform plan -var-file=<file_name.ext>

   $ terraform plan -var-file=values.tfvars

The structure of the file should be key/value pairs like below for the file named values.tfvars

   instance_type = "t2.micro"
   aws_region    = "us-east-1"
   api_key       = "BG^&*UJHJU*&^YUJHY&U"

# Using special files to pass variables
1. Default value => in variable.tf
2. -var flag => command line augument inline
3. -var-file flag => command line augument point to a file
4. terraform.tfvars or terraform.tfvar.jsons => automatically loads the value from this files if it is the current working directory
5. *.auto.tfvars or *.auto.tfvars.json => automatically loads the value from this files if it is the current working directory
6. TF_VAR_ => variables passed using shell environment variables. The variable must start with 'TF_VAR_<INPUT_VARIABLE_NAME>=<VALUE_OF_VARIABLE>'

If a variable is set in more than one location, below is the order of precedence from highest to lowest

# Variable precedence

Quick Reference Table

Priority                    Source                          Loading Method
1 (Highest)                 -var or -var-file flags         Explicitly via CLI
2                           *.auto.tfvars files             Automatically (Lexical order)
3                           terraform.tfvars.json           Automatically
4                           terraform.tfvars                Automatically
5                           TF_VAR_ environment variables   From system shell
6 (Lowest)                  default in variable block       From .tf configuration


# Plan and Apply

Note that the instance_type and api_key do not have default or set anywhere and we will have to supply them
Lets do that using one of the methods above just discussed - using the 'terraform.tfvars'.
The terraform.tfvars file just assigns value to a variable, like :

   instance_type = "t3.micro"

The api_key we can supply during command line deployment when Terraform prompts for it


   $ cd my-stuff/terraform/intermediate/01-variables-output/base_app/

   $ terraform init

   $ terraform fmt -recursive [-recursive will format the modules directory]

   $ terraform validate  [if successful proceed]

[Running below you will be prompted for the api_key. Note that if you start typing the value it is displayed on the screen because it is sensitive. Cancel the operation, ctrl+c, and set any environment variable for the key]

   $ terraform plan  

      var.api_key
      API key to be stored in Secrets Manager.

      Enter a value: 

On the commandline, set an environment (must be prefixed like this TF_VAR_<VARIABLE_KEY>) variable to hold the value of the api_key using below

   $ export TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Linux] 
   
   OR

   $ $env:TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Windows]

The proceed to plan and apply

   $ terraform plan -out m1.tfplan

   $ terraform apply m1.tfplan

Lets show how to modify the infra using commandline variable

   $ terraform plan -var "instance_type=t3.nano" -out m1.tfplan   [overrides the value in terraform.tfvars. Should show the instance is modified not replaced]

   $ terraform apply m1.tfplan  [creates plan for deployment]   

   $ terraform destroy m1.tfplan  [deletes all resources] 
