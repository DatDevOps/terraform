
# https://developer.hashicorp.com/terraform/language/expressions

# https://developer.hashicorp.com/terraform/language/functions

<!-- Expressions and Operator -->

# Terraform Expressions

There are several types of Terraform expression:

1. Literals: these are expressions that Terraform does not need to evaluate to get their actual values like a string, number or Bool with values
   "taco-wagon", 42, and true respectively. The values are literal. 
   You can use literal expressions anywhere but in the source and version arguments of a terraform block in terraform.tf. 
   All values in terraform.tf must be literals as they are process before before Terraform has evaluated the rest of the configuration
   The source and version arguments for a module also have to be literal values for the same reason. Modules are loaded as part of the terraform init process, 
   so the source and version of the module cannot reference something else in the configuration

2. Operators:  That includes basic arithmetic operators like +, -, *, /, and % (modulo). If you need more advanced mathematical operations, 
   you can turn to terraform's built‑in functions.
   Terraform also supports comparison operators and logical operators. That includes =, !=, >, <   
   If you have Bool values, you can also ==, &&, ||, !

3. String manupulation: theres are some ways to manupulate strings like.
    - Interpolations: evaluates an expression and converts it to string - "${<expression>}"
    - Directive: allows you to add if else statements and for loops to your string templates

# Terraform Functions 

Teeraform support Functions in addition to expressions. There are two kinds of functions available, built‑in and provider‑defined. 
As implied by the name, built‑in functions are bundled into the Terraform binary, so no external provider plug‑in is required. 
Provider‑defined functions are bundled in with a provider plug‑in and tend to be specific to operations around that provider's service or platform.   
There's no direct way to define a custom function in HCL. You do have a couple options though. 
You could write a function module that performs the necessary data transformations you want and leverage it in your configurations. 
Or you could write a custom provider in Go with provider‑defined functions.
he syntax for built‑in functions uses the function_name, followed by parentheses, and then inside those parentheses, however many arguments the function takes. 
Some functions take no arguments, like the timestamp function. Some take a fixed number, like the join function, and some take a variable number, like the max function. 
For functions that take a list of arguments, Terraform also supports an expansion symbol of three dots. It goes after a list, and it tells Terraform to expand that list 
into individual arguments for the function. Terraform has over 100 built‑in functions at this point, so HashiCorp has helpfully grouped them into different categories.

Funtion syntax:
   
   #Genral funtion syntax:
    function_name(arg1, arg2, arg3, ...)
   
   #time funtion syntax - no argument:
    time()
   
   #join funtion syntax - fixed argument:
    join(seperator, list)
   
   #variable funtion syntax - returns the max value
    max(3,4,5)

   #list funtion syntax - expands  to max(3,4,5)
   max([3,4,5], ...) 

# -- Exceptional functions --
Among the many functions, there are a handful that have exceptional behavior, and here are just 2 to highlight so you're aware.

- file(path): allows you to include content from outside of Terraform configuration file. 
- templatefile(path, vars):  that brings in a file as a string and interpolates it based off a map of variables.
- uuid() : creates a new value on each time, returning a unique identifier value
- timestamp(): creates a new value on each time, returning system time value

Note: uuid() generates a new value on every plan/apply, which causes perpetual drift. 
For stable UUIDs, use the random_uuid resource instead — it only generates once and stores the value in state.

# Provider-defined Functions
Provider‑defined functions are included in the provider binary, and the functions are aimed at operations that are specific to the provider's platform

    # general syntax:
     provider::provider_name::function_name(arg1, arg2, arg3)
     
    # sample aws syntax - arn_parse funtion
     provider::aws::arn_parse(arn_value)

    # azureRM syntax - parse_resource_id funtion
     provider::azurerm::parse_resource_id(resource_id_value)

# Practical  
- make the CIDR calculation of the subnet's dynamic based off the VPC CIDR block. 
- add names, "team-environment", for the resources in the configuration and in all lowercase.
- add a new tag of owner for the deployment. The owner tag should use the owner input variable if it's set, and if not, the team variable otherwise. 
- Lastly, one of the outputs is the parsed ARN of the VPC. We'll need to use the AWS parse ARN function for that.    

# Soluntions:

   - compare the the main.tf files in "./005-hcl-expressions/base_app" and in "./005-hcl-expressions/01-expression-operators"

   - Note the use of the merge, coalese, lower, format, and cidrsubnet functions in main.tf

   - note the use of the aws specific provider function in output.tf


Well done, run the below:

   $ cd 01-expression-operators/base_app [if only you have not done so above]

   $ terraform init

 
   $ terraform fmt
 
   $ terraform validate

Try the various functions  using terraform console to see the result and play around if need be:

   $ terraform console

   > lower(format("%s-%s", var.team, var.environment))
   
      "taco-wagon-development"

   > merge(local.common_tags, {
   :     Name = format("%s-vpc", local.name_prefix)
   :   })

      {
      "Environment" = "development"
      "ManagedBy" = "Taco-Wagon"
      "Name" = "taco-wagon-development-vpc"
      "Owner" = "Taco-Wagon"
      }

   > cidrsubnet(var.vpc_cidr, 8, 0)

      "10.0.0.0/24"

   > cidrsubnet(var.vpc_cidr, 8, 1)

      "10.0.1.0/24"

   > provider::aws::arn_parse(aws_vpc.main.arn)

   {
      "account_id" = "1234567890"
      "partition" = "aws"
      "region" = "us-east-1"
      "resource" = "vpc/vpc-xxxxx"
      "service" = "ec2"
   }

   > exit

Well done, run the below:

   $ terraform plan -out m1.tfplan [you can stop here if plan is successful or go ahead and create/delete resources below]
 
   $ terraform apply m1.tfplan
 
 
   $ terraform destroy
 
 
 