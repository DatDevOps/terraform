
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

Terraform groups functions by category like numbers, maps, etc. Check them out here: https://developer.hashicorp.com/terraform/plugin/framework/functions

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