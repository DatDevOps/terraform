 <!-- Terraform state fundamentals -->

 Make sure to complete this module in one sitting if using PluralSight because if you dont and PluralSight provisions a new account for it might do so with a new account number and you will get this error when your get to practical-2:

    │ Error: reading Secrets Manager Secret (arn:aws:secretsmanager:us-east-1:329482598717:secret:burrito-barn-dev-api-key-GMOV2I): operation error Secrets Manager: DescribeSecret, https response error StatusCode: 400, RequestID: 59d39fdd-7687-4381-94a9-78f87fceb603, api error AccessDeniedException: User: arn:aws:iam::654654598709:user/cloud_user is not authorized to perform: secretsmanager:DescribeSecret on resource: arn:aws:secretsmanager:us-east-1:329482598717:secret:burrito-barn-dev-api-key-GMOV2I because no resource-based policy allows the secretsmanager:DescribeSecret action
    │ 
    │   with aws_secretsmanager_secret.api_secret,
    │   on main.tf line 109, in resource "aws_secretsmanager_secret" "api_secret":
    │  109: resource "aws_secretsmanager_secret" "api_secret" {
        ...
    }

Note the account number above was different from my new account

# Terraform state inspection

The following command provides information about the state of a resource/s

    $ terraform show  [displays all state data]

    $ terraform state list [list all resources and data sources]

    $ terraform state show ADDR [lists all attributes of a single object. see example below]
    
    $ terraform state show aws_vpc.main [lists all attributes of a single object - aws_vpc_main]

    $ terraform show  [displays all state data]

    $ terraform show -json  [displays all state data in JSON]

Note that although ouputs of your configuration are stored in state, the are not included in the 'terraform show' command.
To access output state, use the terraform output commands

    $ terraform output [shows all state  stored outputs]

    $ terraform output -json [shows all state  stored outputs in JSON]

    $ terraform output <name_of_output> [shows a specific output stored in state ]

    $ terraform output -raw <name_of_output> [shows a specific output stored in state with quotation marks ]

    $ terraform state pull  [sends raw state to standard out - terminal]

Pulling and Pushing state data around:    

    $ terraform state pull > local.tfstate  [sends raw state to the file local.tfstate]

    $ terraform state push  <path_to_remote_location> [sends raw state to a remote path location]

Soon to be deprecated mv and rm commands:

    $ terraform state mv <SOURCE> <DESTINATION>  [moves a resource to a new address]

    $ terraform state rm ADDR [removes a resource from state]

Managing state synchronization and drift detection using state refresh using '-refresh-only'
Below are some kind of drift and informs the decision to use or not use the '-refresh-only' options
- Approved drift: made outside the code and approved (you  want to keep this change)
- Unauthorized drift: made outside the code and unapproved (use 'terraform plan' and terraform apply' to revert changes)
- Continual drift: made by a service you permitted (ignore the change)

# Practical 1
- Someone change the instance size from t2.micro to t3.nano using aws cli or console and not  terraform configuration

- Keep the change without disruption (because it was an approved change)

Now:
- Copy the content of /01-variables-input-output/004/base_app to /terraform/intermediate/02-terraform-state
- Now delete the m4.tfplan file

On the commandline, set an environment (must be prefixed like this TF_VAR_<VARIABLE_KEY>) variable to hold the value of the api_key using below

   $ export TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Linux] 
   
   OR

   $ $env:TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Windows]

Then run:

    $ cd /terraform/intermediate/02-terraform-state/base_app

    $ terraform init [only if you have not done this before. But I have done so and skipping it]

    $ terraform fmt -check

    $ terraform fmt 
    
    $ terraform fmt -check [should return nothing now]

    $ terraform validate [proceed if successful]

    $ terraform plan -out m1.tfplan [check to see all resource name now follow the requirement requested above]

    $ terraform apply m1.tfplan

Now go to the  console and change the instance size or use the commands below to get theinstance id and change its size

    $ terraform state list [list all resources and data sources. Note that the instance is 'aws_instance.web']

    $ terraform state show aws_instance.web [shows all the instance properties]

    $ terraform state show aws_instance.web | grep "id" [returns only the  instance id amongs other occurence of id's. Copy the id]

    $ instance_id="i-0d72cab60e192d1d1" [set the id as env variable]

    $ aws ec2 wait instance-stopped --instance-ids $instance_id --profile my-sandbox [stops the instance and wait for it to stopp b4 proceeding]

    $ aws ec2 modify-instance-attribute --instance-id $instance_id --instance-type '{"Value": "t3.nano"}'  --profile my-sandbox  [Change the instance type]

    $ $ aws ec2 start-instances --instance-ids $instance_id --profile my-sandbox [Start the instance]

    $ terraform plan -refresh-only [should show, ~, the modification made on the console]

        ...
        ...
        # aws_instance.web has changed
        ~ resource "aws_instance" "web" {
            id                                   = "i-0d72cab60e192d1d1"
            ~ instance_type                        = "t2.micro" -> "t3.nano"
        ...
        ...

    $ terraform apply -refresh-only [resolves the difference in state and enter 'yes' when prompted]

Update terraform.tfvars to use the new instance type and run plan

    $ terraform plan [the result should be no changes since our state matches our configurations]

*NB
'terraform plan -refresh-only' — This queries AWS for the current real-world state of your resources and compares it to what Terraform has recorded in its state file. It shows you exactly what drifted (e.g., instance type changed from t2.micro to t3.nano) without proposing to revert or modify anything. It's a safe "look but don't touch" operation.

'terraform apply -refresh-only' — This updates your local state file to match the real-world state discovered above. After this runs, Terraform's state now records t3.nano as the current instance type. No infrastructure changes are made — only the state file is updated.

Why both? Together they let you "accept" an out-of-band change. Without them, a regular terraform plan would see the drift and propose reverting the instance back to t2.micro (the value still in your config). By refreshing state first, you acknowledge the change. You'd then also update your .tf files (e.g., terraform.tfvars) to match, so future plans show no



# Practical 2
- change resource label without creating a new resource because of chnage of label
- Remove a resource from configuration without deleting it

<!-- change resource label -->
Change the label of the instance in main.tf from web to app 

    resource "aws_instance" "app" {
        ...
        ...
    }

Also change, the reference of the instance below to match the new label

    output "ec2_public_ip" {
    description = "The public IP address of the EC2 instance."
    value       = aws_instance.app.public_ip
    }

Now running a plan will show terraform deleting the resource ' - aws_instance.web' and creating a new resource ' + aws_instance.app' because aws_instance.app is not in state. Our intention may not be to delete the old resource and create a new one.

    $ export TF_VAR_burrito_barn_dev_api_key="BG^&*UJHJU*&^YUJHY&U"  [check locals, terrraform.tfvars, and variable.tf to see how name is formed]

    $ terraform plan -out m1.tfplan  [Shows a new resource will be created and the old one deleted]

We can inform Terraform of our intent not to delete the old resource or create a new one using the command: terraform state mv <SOURCE> <DESTINATION>

    # not recommended way of changing state
    $ terraform state mv aws_instance.web aws_instance.app [this keeps the old and change chnages the state to march the new config ]

    OR in main.tf (recommended)

    moved{
        from = aws_instance.web
        to = aws_instance.app
    }

Add the moved block comment back in main.tf and run plan

    $ terraform plan -out m1.tfplan [moves 'aws_instance.web' to 'aws_instance.app' without chnages to the infrastructure]

<!-- remove resource from config without deleting it -->

Comment out the  EC2 resource and it SG in main.tf and all associated outpput in outputs.tf

    $ terraform plan -out m1.tfplan [terraform tries to delete the EC2 and SG from state. Not what we want] 

To move a resource to a new address run: terraform state rm <ADDRESS>

    # not recommended
    $ terraform state rm aws_instance.web [ removes the  resource from state with deleting it]

    OR in main.tf (recommended)

    removed{
        from = aws_instance.web
        lifecycle{
            destroy = false
        }
    }    

Add the removed blocks and run plan

    $ terraform plan out m1.tfplan [now shows that the resource will be removed from state rather delete it]

