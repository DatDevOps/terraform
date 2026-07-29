
<!-- Terraform Expressions -->
Terraform supports many type of expressions
- Literal expressions
- Object and attribute refences
- Standard arithmetic and logical operators (AND, OR, <, >, =, depending on the data)
- Conditional expressions

<!-- Terraform Functions -->
Terraform functions are built-in to terraform

    func_name()  [takes no argument]
    func_name(arg1, arg2, arg3, ...)  [takes many argument]

Terraform groups functions by category like numbers, maps, etc. Read more about each below:
# https://developer.hashicorp.com/terraform/language/functions
# https://developer.hashicorp.com/terraform/plugin/framework/functions

Lets now use some functions 
- Read in our userdata script and passing variables dynamically: 

    templatefile(file_path, {map of variables})

- make all naming lowercase

    lower(local.naming_prefix)

- Add new tags to existing common_tags local variable

    merge(local.common_tags, {map of additional tags})

<!-- Testing Terraform functionswith Terraform Console -->

Lets now test some functions using the awesome feature of Terraform Console

Move into the current module project directory and run:

    $ terraform console

    > min(4,5,16)                    ======> returns the value of the 3 numbers
    
        4

    > lower("TACOCAT")               ======> converts to lowercase
    
        "tacocat"

    > local.common_tags              ======> returns the value of the local variable common_tags

        {
        "BillingCode" = "8675309"
        "Company" = "Globomantics"
        "Environment" = "dev"
        "Project" = "tacowagon"
        }

    > merge(local.common_tags, {Name = "${local.prefix}-vpc"})
        {
        "BillingCode" = "8675309"
        "Company" = "Globomantics"
        "Environment" = "dev"
        "Name" = "tacowagon-dev-vpc"
        "Project" = "tacowagon"
        }


    > merge(local.common_tags, {Name = lower("${local.prefix}-vpc")})               ===> adds an new field to the existing common_tag local variable

        {
        "BillingCode" = "8675309"
        "Company" = "Globomantics"
        "Environment" = "dev"
        "Name" = "tacowagon-dev-vpc"
        "Project" = "tacowagon"
        }   


    > merge(local.common_tags, {Name = lower("${local.common_tags.Company}-vpc")})   ===> adds an new field to the existing common_tag local variable and ensure the  value is all lowercase

        {
        "BillingCode" = "8675309"
        "Company" = "Globomantics"
        "Environment" = "dev"
        "Name" = "globomantics-vpc"
        "Project" = "tacowagon"
        }

    > exit                           ======> exit terrform console


# OTHER SAMPLES OF FUNCTIONS ARE SHOW BELOW
# See also: https://developer.hashicorp.com/terraform/language/functions

- terraform console [open the terraform console to test the following functions]

- lookup: Retrieves the value of a single element from a map based on its key.

    # HCL provided
    # Usage
    # Assuming map is { "us-east-1" = "t2.micro", "us-west-2" = "t3.micro" }
    instlookup(var.instance_map, var.aws_region, "t2.micro")

    # Result: "t2.micro"

- length: Returns the number of elements in a list, map, or set, or the number of characters in a string

    # HCL provided
    # Usage
    sublength(var.subnet_cidrs)

    # Result: 2

- contains: Determines if a list or set includes a specific value.

    # HCL provided
    # Usage
    contains(var.users, "alice")
    # Result:true

    contains(var.users, "admin")
    
    # Result: false

- join: Concatenates a list of strings together using a specified separator.

    # HCL provided
    # Usage
    join("-", var.users)

    # Result: "alice-bob"
    
    join(",", var.users)

    # Result: "alice,bob"

    join(",", ["web", "production", "us-east"])

    # Result: "web,production,us-east"

- replace: Searches a string for a substring and replaces it with another

    # HCL provided
    # Usage
    replace("hello world", "world", "HCL")

    # Result: "hello HCL"

- lower: Converts all uppercase characters in a string to lowercase

    # HCL provided
    # Usage
    lower("PRODUCTION")

    # Result: "production"

- template: Reads a separate file, render its content dynamically, and inject HCL variables.
            The function takes two arguments: the path to your template file and a map of variables:templatefile(path, vars)

    # HCL provided
    # Usage
    templatefile("./templates/startup_script.tpl", {environment = "dev"})

    # Result:
        <<EOT
        #! /bin/bash
        sudo amazon-linux-extras install -y nginx1
        sudo service nginx start
        sudo rm /usr/share/nginx/html/index.html
        sudo cat > /usr/share/nginx/html/index.html << 'WEBSITE'
        <html>
        <head>
            <title>Taco Team Server - dev</title>
        </head>
        <body style="background-color:#1F778D">
            <p style="text-align: center;">
                <span style="color:#FFFFFF;">
                    <span style="font-size:100px;">Welcome to the dev website! Have a &#127790;</span>
                </span>
            </p>
        </body>
        </html>
        WEBSITE
        EOT

- file: Reads the contents of a file and returns them as a literal string.

    # HCL provided
    # Usage
    file("${path.module}/templates/startup_script.tpl")

    # Result
        <<EOT
        #! /bin/bash
        sudo amazon-linux-extras install -y nginx1
        sudo service nginx start
        sudo rm /usr/share/nginx/html/index.html
        sudo cat > /usr/share/nginx/html/index.html << 'WEBSITE'
        <html>
        <head>
            <title>Taco Team Server - ${environment}</title>
        </head>
        <body style="background-color:#1F778D">
            <p style="text-align: center;">
                <span style="color:#FFFFFF;">
                    <span style="font-size:100px;">Welcome to the ${environment} website! Have a &#127790;</span>
                </span>
            </p>
        </body>
        </html>
        WEBSITE
        EOT    

- fileexists: Checks if a file exists at a given path, returning a boolean.

    # HCL provided
    # Usage
    fileexists("${path.module}/templates/startup_script.tpl")

    # Result: true

    fileexists("${path.module}/templates/end_script.tpl")

    # Result: false

- jsondecode: Parses a JSON-encoded string and returns it as a corresponding HCL map/list.

    # HCL provided
    # Usage
    jsondecode(var.json_string)

    # Result
    {
        "enable_monitoring" = true
        "env" = "production"
        "instance_count" = 3
    }

    jsondecode(var.json_string).enable_monitoring
    
    # Result: true

    jsondecode(var.json_string).instance_count

    # Result: 3

- max / min: Returns the largest or smallest number from a series of numbers

    # HCL provided
    # Usage
    max(10, 50, 20)
    
    # Result: 50

    min(10, 50, 20)

    # Result: 10


Lets now update our main.tf using the functions above .

Once you are done, validate and format you code and the apply the changes using the below:

    $ terraform init [only if you have not done this before. But I have done so and skipping it]

    $ terraform fmt -check

    $ terraform fmt 

    $ terraform validate

    $ terraform plan -out m5.tfplan
    
    $ terraform apply m5.tfplan

    $ terraform destroy  [enter 'yes' when prompted]


Now go ahead and add the local variables to the main.tf file

Here we did not do 'terraform plan' or 'terraform apply'