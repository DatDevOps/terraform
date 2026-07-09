<!-- Terraform Data Types -->

# Terraform Data types: https://developer.hashicorp.com/terraform/plugin/framework/handling-data/types

1. Primitive
    - String
    - Number
    - Bool

Terraform supports strings, numbers, and Bool. Strings are any collection of Unicode characters. 
Strings are constructed using double quotes or heredoc syntax. Single quotes are not supported to declare a string. 
Strings support the use of interpolation and directives, as we've already learned.

#string
    "I am a string" # valid string with double quotes
    'I am a string' # invalid string with single quotes
    "\n, \r, \t, \, \\, \uNNNN" #various escape sequence
    "C:\\Users\\ned\\Documents\\taco-recipe.md # windows file path
    $${<expression>} #interpolation escape
    %%{<directive>} #directive escape
#number are integers, decimals and scientific notations, e.g. 8, 1.21, 123+e3
#Bool are either true or false    

2. Collection
    - List => [ an array of same type. can't mix and match]
    - Set => (contains unique values of same type)
    - Map => {key/value pairs}

#list examples and reference

    locals {
        toppings = ["salsa", "cheese", "lettuce", "guac"]
        ports = [22, 80, 443]
    }

    #refernce
    local.<name_label>[<element_number>]
    local.toppings[2] # returns "lettuce" and does not support negative index
    local.toppings[*] # * is refered o as the splat expression and returns all lisy items - "salsa", "cheese", "lettuce", "guac"

#maps and reference

    local{
        taco = {
            meat = "al-pastor"
            cheese = "jack"
            tortilla = "corn"
        }
    }

    #reference
    local<name_label>.<key_name> OR local<name_label>.["key_name"] 
    local.taco.cheese # returns "jack"
    local.taco["cheese"] # returns "jack"

#sets and reference

    local{
        cheese = toset(["salsa", "cheese", "lettuce", "guac"])
        
    }  

    #reference: you can get individual items like above but you can do so with a for loop
    local.<name_label>[*] #returns all items  
    local.cheese[*] #returns all items  
    [for cheese in cheeses: upper(cheese)] #gets each item and converts it to uppercase    

3. Structural (allows you to mix Collection data types)
    - Tuples [same as list but does not have to be of same type]
    - Objects [same as maps]

    #tuple and reference
    [1, ["a","b"], true]

    #refernce like list
    local.<name_label>[<element_numner>]

    #object and reference
    {
        subnet_count = 2
        allowed_port = [80, 443]
        tags = {
            environment = "dev"
            project ="taco-wagon
        }
    }

    #reference like maps
    local<name_label>.<key_name> OR local<name_label>.["key_name"]    

4. null:  Terraform interprets a null when it's used as the value for an argument. When a resource or a data source argument is set to null, 
Terraform treats it as if the argument was not set at all, using the default value for that argument as defined in the provide  

5. any: is meant to handle scenarios where you don't know what the data type is and you don't care because you're simply passing that value through to another object. 
And that makes sense. If you try to reference the structure of an unknown data type, you're probably going to get it wrong. If I try to get an element out of a list and the actual data type turns out to be a map, Terraform's going to error out. If I do know the structure ahead of time, I should just properly type my inputs.

any should be used sparingly, if at all. It is not a way to avoid specifying a data type

    variable "monitoring"{
        type = bool
        default = null
    }

    resource "aws-instance" "web" {
        ...
        ..
        monitoring = var.monitoring # uses the default value of aws for this resource 
    }

- any  

    variable "json_data" {
        description = "JSON data of unknow structure"
        type = any
    }

    variable "mastery_list" {
        description = "list of unknown type"
        type = list(any)
    }

# Variable defintion with data types    
You can use all the above data types to meet your need when you define a variable.
This allows terraform to validate the value supplied to make sure it matches the definition in variable.tf

- Primitive data type definition

   # string variable
   variable "aws_region" {
    type        = string
    description = "Region to use for AWS resources"
    default     = "us-east-1"
   } 
    # number variable
   variable "subnet_count" {
    type        = number
    description = "The number of AWS VPC subnet to create"
    default     = 3
   } 
   # bool variable
   variable "ec_monitoring" {
    type        = string
    description = "Enable or disable EC2 monitoring"
    default     = bool
   } 


- collections

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

- structural data type definition
   # tuple variable
   variable "user_details" {
    type        = tuple([string, mp(string), bool]) # all the type you want to accept
    description = "details of a specific user"
    default     = "us-east-1"
   } 

   variable "vpc_info" {
    type        = object({
        vpc_name = string
        subnet_count = number
        cidr_ranges = list(string)
        nat_gateway = bool
    })
    description = "All required vpc subnet info"
    default     = {
        vpc_name = "dev-vpc"
        subnet_count = 3
        cidr_ranges = ["10.0.0.1/24","10.0.0.2/24","10.0.0.3/24"]
        nat_gateway = true
    }
   } 


You can make input variables as complex as you want, but I really do recommend against it. 
The more complex the input variable, the harder it will be to maintain, validate, and for the consumer to use. 
However, having an input variable that is simply one to one with the arguments for a resource is a bit of an anti‑pattern.


# Optional variable attribute
syntax:
    type = object({
        key_name = optional(<data_type>, <default_value>)
        key_name = optional(<data_type>)
    })

The optional keyword is applied to the value type in an object. So for instance, we have an input variable below that is defining a server configuration with an object. 
We'd like to give the consumer the flexibility to configure things like monitoring, user_data, and key_name.

As it stands now, the user has to give values for every key, even if they don't want to. The solution is the optional keyword

    variable "server-config"{
        type = object({
            instance_type = string
            public_subnet = bool
            user_data = string
            key_name = string
            monitoring = bool
        })
    }

With the updated config below, the end user can omit any of these optional values, and Terraform will substitute the default value or null.

    variable "server-config"{
        type = object({
            instance_type = string
            public_subnet = bool
            user_data = optional (string)
            key_name = optional(string)
            monitoring = optional(bool, false)
        })
    }

# Practicals
- add a new load balancer and more instances
- new variable for application settings
    * instance information: including the count, instance type, monitoring, listener port, and protocol
    * load balancer information, including the port, protocol, and health check.  
    * optional variables including the instance type, set to a default of t3.micro, and monitoring with no default, so it sets to null.

Now:

    $ cd 05-hcl-expressions/04-data-structure-type [move into module directory]

    $ cp -R  05-hcl-expressions/03-meta-arguments/base_app . [ copies base_app from previous module 2 to module 3 directory]
    
    $ rm -rf m3.tfplan [deletes the plan generated from the previous module]

Study the terraform.tfvars, variable.tf, and outputs.tf in the previous module - 05-hcl-expressions/3-meta-arguments/base_app

Now study the new main-ec2.tf with the added code that contains the EC2 and ALB configurations, the new "application_config" in variable.tf, the new output "lb_public_dns" added in outputs.tf in place of the ec2 dns output, and the reference of our new application_config variable in main.tf to meet the above requirements

After understanding the additions, run the below: 

    $ terraform init [skip if the project is already initialized] 
    
    $ terraform fmt 

    $ terraform validate

    $ terraform plan -out m4.tfplan

    $ terraform apply m4.tfplan
    
    $ terraform destroy
