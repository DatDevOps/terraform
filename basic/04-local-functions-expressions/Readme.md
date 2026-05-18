NB: The entire content of 03-input_output module but the m2.tfplan file was coppied over so we don't repeat all the steps again.

Now we add some more function expressions and use locals

<!-- Locals -->
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
        }

Local vallue reference:  

    local.<key>

    For example:
    local.instance_prefix  [returns 'globo']
    local.common_tags.company [returns 'Globamantics']


Now lets add the following variables and create a locals.tf file to reference them in our infra
- Company
- Project
- Environment
- Billing code

Now go ahead and add the local variables to the main.tf file

Once you are done, validate and format your code and the apply the changes using the below:

    $ terraform init [only if you have not done this before. But I have done so and skipping it]

    $ terraform fmt -check

    $ terraform fmt 

    $ terraform validate
If your validation is succesful, note the below and proceed to module 5

NB: Here we did not do 'terraform plan' or 'terraform apply'
