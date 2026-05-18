NB: The entire content of /intermediate/01-variables-output/002/base_app module but the m2.tfplan file was coppied over so we don't repeat all the steps again.

Now we add some more function expressions and use locals


<!--02 Local Variable -->
Local values are:
- Internal temporary values
- Replace repeated values
- Used for data transformation
- can reference variables

local value syntax:

    locals {
        key =value
    }

    For example:

        locals{
            instance_prefix = "globo"
            common_tags = {
                company        = "Globomantics"
                project        = var.project       # references a variable value
                billing_code   = var.billing_code  # references a variable value
            }
            public_subnet ={
                name  = "pubsub1"
                tags  = var.tags  ======> references a defined variable
                cidr_ranges = ["10.0.0.0/24", "192.168.1.0/24"]
                is_public  = true
            }
        }

Local vallue reference:  

    local.<key>

    For example:
    - local.instance_prefix  [returns 'globo']
    - local.common_tags.company [returns 'Globamantics']
    - local.public_subnet.cidr_ranges {returns ["10.0.0.0/24", "192.168.1.0/24"]}

Local values can be defined in the main.tf or local.tf file. 
Some define local variables specific to a main.tf inside the main.tf
Other, store global variables in the local.tf file and specific configuration local variables in main.tf
Use whatever work for you and do weel to add a readme file for you users


Now lets add the following variables and create a locals.tf file to reference them in our infra
- Add default tags to VPC, instance, and Bucket
- Naming prefix for all resources should be 'project-environment'
- Define resource names in one place

Now go ahead and add the local variables to the main.tf file

Run the below if you have not already done so:

On the commandline, set an environment (must be prefixed like this TF_VAR_<VARIABLE_KEY>) variable to hold the value of the api_key using below

   $ export TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Linux] 
   
   OR

   $ $env:TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Windows]

Once you are done, validate and format your code and the apply the changes using the below:

    $ cd my-stuff/terraform/intermediate/01-variables-output/003/base_app

    $ terraform init [only if you have not done this before. But I have done so and skipping it]

    $ terraform fmt -check

    $ terraform fmt 
    
    $ terraform fmt -check [should return nothing now]

    $ terraform validate [proceed if successful]

    $ terraform plan -out m3.tfplan [check to see all resource name now follow the requirement requested above]

    $ terraform apply m3.tfplan

Check various resource names and after which you should delete all resources    

    $ terraform apply m3.tfplan