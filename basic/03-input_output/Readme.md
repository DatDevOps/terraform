<!-- Variable Syntax  -->

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

# Terraform Data types: https://developer.hashicorp.com/terraform/plugin/framework/handling-data/types

1. Primitive
    - String
    - Number
    - Bool

2. Collection
    - List => [ an array o same type. can't mix and match]
    - Set => (contains unique values)
    - Map => {key/value pairs}

3. Structural (allows you to mix Collection data types)
    - Tuples [same as list]
    - Objects [same as maps]

# practical sample of variables types:

   variable "aws_region" {
    type        = list(string)
    description = "Region to use for AWS resources"
    default     = ["us-east-1", "us-east-2", "us-west-1", "us-west-1"]
   }    

   variable "aws_instance_sizes" {
    type        = map(string)
    description = "Region to use for AWS resources"
    default     = {
        small  = "t3.micro"
        medium = "m4.large"
        large  =  "m4.xlarge"
    }
   }    

# Variable reference

1. List

    var.<name_label> [<element_number>]  

    var.aws_region  = returns the full array of ["us-east-1", "us-east-2", "us-west-1", "us-west-1"]
    var.aws_region[0]  = "us-east-1"
    var.aws_region[2]  = "us-west-1"
    var.aws_region[3]  = "us-west-1"

2. Map

    var.<name_label>.<key_name>  OR
    var.<name_label>["key_name"]

    var.aws_instance_sizes.small = "t3.micro"
    var.aws_instance_sizes["small"] = "t3.micro"
    
    var.aws_instance_sizes.medium = "m4.large"
    var.aws_instance_sizes["medium"] = "m4.large"
    
    var.aws_instance_sizes.large = "m4.xlarge"
    var.aws_instance_sizes["large"] = "m4.xlarge"


<!-- Output Syntax -->

    output "name_label" {
        value = value
        description = "string"
    }
    

# Formatting code to meet Hasicorp standard
Change to working directory:

    $ cd my-stuff/terraform/basic/03-input_output/

Then run the below in the  current working directory. This command will return a list of files that do not meet the formatting standard  and need formatting. It does not check sysntaxand logic

    $ terraform fmt -check  

        main.tf

Lets now fix the formatting issue using the same command without the -check flag. It does not check sysntaxand logic

    $ terraform fmt 

# Validating code   

It requires 'terraform init' to be run because it requires provider pluggins to check for syntax, logic/validation

    $ terraform init  [do this if you  have not initialize your configuration]

    $ terraform validate

        Success! The configuration is valid.

It was success! You can introduce an error by referencing a variable not declared in variable.tf in main.tf and watch the validation in action

# Passing variables

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
Not that the variables http_port and ec2_instance_type were declared without default values. 
Lets do that using one of the methods above just discussed - using the 'terraform.tfvars'.
The terraform.tfvars file just assigns value to a variable, like :

    variable_name = variable_value

Now run:

    $ terraform fmt -check [2 files not well formatted]

        main.tf
        terraform.tfvars

    $ terraform fmt  [the 2 files now formmatted]

        main.tf
        terraform.tfvars

    $ terraform fmt [nothing returned because files are well formatted]

    $ terraform validate  [syntax and logic looks good]

        Success! The configuration is valid.

    $ terraform plan -out m2.tfplan

    $ terraform apply m2.tfplan

Copy the aws_instance_public_dns  value from the terminal output and paste in your browser

    aws_instance_public_dns = "ec2-3-219-45-218.compute-1.amazonaws.com"

You cannow view the webpage. Success!

Now delete all infrastructure created

    $ terraform destroy  [enter 'yes' when prompted]