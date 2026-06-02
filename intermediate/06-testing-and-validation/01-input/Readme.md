<!-- Input variable Validation -->

# Variable Validation Options
A key tenet of software development is validation of inputs, guarantees, and assumptions, or to put it another way, trust nothing and verify everything. 
Your end users can and will break your code in new and exciting ways. 
By putting proper validation in place, you can safeguard against the worst abuses and fail gracefully when an error occurs. 
Variables are great because they make your configuration more dynamic and reusable, but they also let end users submit information to Terraform that may not be valid. 
Terraform includes two features that help you protect against bad input, the type argument and the validation block. 
The type argument in a variable block allows you to define the expected data structure of valid input. 
You can declare simple data types like a number, a list, or a map. You can even define complicated objects with named fields and optional values. 
When an end user submits an input variable value, Terraform will check the contents against the expected data structure. 
If the two don't match, Terraform will reject the submitted value. 
Terraform will try and do some simple type conversion, like turning a number into a string or a string into a Bool. 
If that type conversion fails, Terraform will also throw an error.

    variable "example"{
        type = string
        description: "..."        
    }

# Validation Block Syntax
The type argument is great for checking the structure of the variable value, but it doesn't inspect the actual value itself. That's where validation blocks come in. 
Validation blocks go inside of the variable block, and you can include multiple instances of the block for a single variable. 
Terraform will process all of the validation blocks in a variable and display errors for any validations that fail. 
Inside the validation block, you have access to any values that are known when the variable evaluation occurs, things like local values, data sources, and other variables. 
As long as the value will be known during validation, you can reference it. Computed values from resources may not be available and could cause an error to be thrown. 

Let's check out the syntax. The validation block goes inside of a variable block. It starts with the validation keyword and doesn't take any block labels. Inside the block, there are two required arguments. The first is the condition, and its value must evaluate to true or false. If the value is true, then the validation passes and Terraform's happy. If the value is false, then the validation fails and Terraform prints the contents of the error message. 
The second argument defines the error message, and it's called error_message. That's the message that Terraform will print. 
The value is a string, and it needs to be a full sentence. You can include references in your error message string to help point out where things went wrong. 

    variable "example"{
        type = string
        description: "..." 

        validation{
            condition = true | false
            error_message = "must  be a string value"
        }       
    }

There are some expressions and functions you may find extremely helpful when writing conditions. 
Remember that the value has to be evaluated to true or false. Terraform supports the usual assortment of comparison operators. 

#comparison operators: 

    ==, !=, >, <

#logical operators: 

    &&, ||, !

#Some functions and uses (check docs for details and more function usecases)
    - contains()
    - endswith() and startswith()
    - alltrue() and anytrue()
    - fileexists()
    - issensitive()
    - can() and can(regex())

Can checks to see if the argument inside throws an error or not. You can combine this with another function like regex. 
Regex will throw an error if there's no matching pattern, and can will catch that and render it as false. 
If the regex is successful, then can will render as true.

# Practicals

    $ cd 06-testing-and-validation/01-input

    $ cp -R 06-testing-and-validation/base_app .

    $ terraform init

The variable.tf has been updated with variable validation with below:

    variable "company_name" {
    type        = string
    description = "Company name for resource naming"
    
    # Module 1: Alphanumeric, 3-20 characters
    validation {
        condition     = length(var.company_name) >= 3 && length(var.company_name) <= 20
        error_message = "The company_name must be between 3 to 20 characters long."
    }

    validation {
        condition     = can(regex("^[a-zA-Z0-9]+$", var.company_name))
        error_message = "The company name must be alphanumeric."
    }

    }

    variable "environment" {
    type        = string
    description = "Environment name (dev, staging, prod)"
    
    # Module 1: Add validation to allow only dev, staging, or prod
    validation {
        condition     = contains(local.allowed_env, var.environment)
        error_message = "The environment must be one of the following: ${join(", ", local.allowed_env)}."
    }
    }

    variable "aws_region" {
    type        = string
    description = "AWS region for resource deployment"
    default     = "us-east-1"
    
    # Module 1: Add validation to ensure US regions only
    validation {
        condition     = startswith(var.aws_region, "us-")
        error_message = "The AWS region must be a valid US region (e.g., us-east-1, us-west-2)."
    }
    }

    variable "availability_zones" {
    type        = number
    description = "Number of availability zones to use"
    
    # Module 1: Add validation to ensure at least 2 AZs are provided
    validation {
        condition     = var.availability_zones >= 2
        error_message = "At least 2 availability zones must be specified."
    }
    }

    variable "vpc_cidr" {
    type        = string
    description = "CIDR block for the VPC"
    default     = "10.0.0.0/16"
    }

    variable "instance_type" {
    type        = string
    description = "EC2 instance type for the web server"
    default     = "t3.micro"
    
    # Module 1: Add validation for approved instance types (t3.micro, t3.small, t3.medium)
    validation {
        condition     = contains(local.allowed_instance_types, var.instance_type)
        error_message = "The instance_type must be one of the following: ${join(", ", local.allowed_instance_types)}."
    }
    }



Lets move to the terraform console for some test. Lets use the company_name variable:

    $ terraform console

    > regex("[^a-zA-Z0-9]", "*_abc")

        "*"

    > regex("[^a-zA-Z0-9]", "abc123")           ===> #see not below NB below

        ╷
        │ Error: Error in function call
        │ 
        │   on <console-input> line 1:
        │   (source code not available)
        │ 
        │ Call to function "regex" failed: pattern did not match any part of the given string.
        ╵

    > can(regex("[^a-zA-Z0-9]", "abc123"))

        false

    > !can(regex("[^a-zA-Z0-9]", "abc123"))

        true  

    > exit  

You can test the other variables on  the console if you wish

# NB: 
Because the regex function throws an error if the pattern isn't found. I need to wrap this in a can function. 
The can function returns true if the expression inside has no error and false if it does.
Now we get back a false with a valid string, so I'll add the exclamation point to the front to invert the result. 
Now I get back a true if the string has no special characters and a false if it does. 
I'll update the variable with the new validation block using the condition we just built in the terraform console, 

Now run:

    $ terraform fmt

    $ terraform validate

    $ terraform plan -out m1.tfplan

    $ terraform apply m1.tfplan

    $ terraform destroy

You can edit any of the below values in terraform.tfvar to an invalid value and run a plan to see the plan fail

        environment        = "dev" #change to "qa" or "stg" to test
        aws_region         = "us-east-1"  #change to "eu-west-1" to test
        availability_zones = 2 #change to "1" or "0" to test


