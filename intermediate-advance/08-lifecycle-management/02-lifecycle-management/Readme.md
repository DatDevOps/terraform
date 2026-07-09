<!-- Life Cycle Management -->

# Resource Lifecycle Control
Controlling resource dependency is one aspect of a resource's lifecycle, but there's more to it. 
What if you wanted to replace a resource each time another resource was updated or you wanted to let another application manage some of the settings for a resource without Terraform interfering? 
These use cases and more can be supported through the lifecycle block. The lifecycle block is supported by all resource types, and it includes several arguments. 
We'll cover most of these in greater detail throughout the module, but here's a quick overview. 

    lifecycle {
        action_trigger  {}
        Create_before_destroy = true | false
        prevent_destroy = true | false
        ignore_changes = [list_of_references] 
        replace_triggered_by = [list_of_references]
        precondition  {}
        postcondition  {}        
    }

- The action_trigger block triggers a Terraform action based on an event with the resource. 

- Create_before_destroy alters the default sequence for resource recreation. 

- Prevent_destroy blocks the destruction or recreation of a resource when set to true. 

- Ignore_changes takes a list of resource attributes that Terraform will not be managing. 

- Replace_triggered_by takes a list of resources that will trigger a recreation of the current resource. 

- Precondition checks if a condition is true before evaluation of the object. 

- Postcondition checks if a condition is true after the evaluation of an object. 


Pre and postconditions support data sources and ephemeral resources. The rest of the arguments are for managed resources only. 
We will not be covering the pre and postcondition blocks, as those are part of the Terraform: Validation and Testing course. 
And the action_trigger block is part of a future Terraform: Actions course.

# Resource recreation
Resource recreation can be triigered by any of the following:   
    - Change of an immutable attribute
    - When another resource is updated
    - Manual replacement using the CLI

<!-- Manual replacement -->
The option can be used with both terraform plan and terraform apply, and it can be repeated multiple times for each resource that should be replaced. 
This option is for situations where you know something is wrong with the resource, but it's not something Terraform is aware of that would trigger a regular recreation. 
When Terraform recreates a resource, its default behavior is to destroy the existing resource and then create its replacement. 
That's why the symbol for recreation is ‑/+ to indicate the order of operations.

    $ terraform plan -replace="aws_instance.web"  [replaces a resource as part of an execution plan]

    $ terraform apply -replace="aws_instance.web"  [replaces a resource as part of an execution plan]

However, there may be scenarios where you would like Terraform to create the replacement first and then destroy the old resource. 
Usually, this is due to a platform dependency issue, where the existing resource cannot be removed until it's no longer in use. 
Creating the replacement first and swapping out all the references usually fixes that problem. 
In fact, we have this exact problem with the Taco Wagon security group 


    $ cd my-stuff/terraform/intermediate/08-lifecycle-management/02-lifecycle-management/

    $  cp -R ../01-graph-dependencies/base_apps/ .

    $ cd base_apps/taco_wagon/

    $ terraform init [if not done already]
    
    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out m2.tfplan

    $ terraform apply m2.tfplan

# Practicals Globomantics Scenario
    1. The S3 logging bucket should be created before the EC2 instance so no logs are missed and protected against deletion [done in previous module]
    2. The security group needs to be renamed
    3. The S3 asset cache should be recreated when the application version is updated. 
    4. Finally, the tags on the EC2 instance are being managed by a tag policy at the organization level, 
      and Terraform keeps reverting the changes. We can solve all of these issues through Terraform.  


# # Practical 2
<!-- create_before_destroy -->
I have the main.tf file open for the Taco Wagon deployment, and we're looking at the aws_security_group. 
Its current name is taco‑wagon‑sg, but that does not follow the naming standard for Globomantics. 
It should use the local naming prefix followed by sg. I'll update the name argument to be {local.naming_prefix}sg

Then I'll pull up the terminal and run a terraform apply. The plan should generate successfully. 
And if we scroll up and look at the results, the security group needs to be recreated to change the name. 
Scrolling up a little bit more, the AWS instance will be updated in place to reference the new security group whose ID we don't yet know. 
I'll approve the plan, and it will first attempt to destroy the security group. That operation is going to fail. 
Why? Because the security group cannot be destroyed while it's in use by an EC2 instance.  

        $ cd base_apps/taco_wagon/

In main.tf update the security group aws_security_group.main name from "taco-wagon-sg" to

        resource "aws_security_group" "main" {
            #name   = "taco-wagon-sg"
            name   = {local.naming_prefix}sg
            vpc_id = aws_vpc.main.id
        }

        $ terraform plan -out m2.tfplan 

        $ terraform apply m2.tfplan [That operation is going to fail because the  SG is in use and cannot be deleted or replace]

            aws_vpc_security_group_egress_rule.all_outbound: Destroying... [id=sgr-03e4b693a63fd38c8]
            aws_vpc_security_group_ingress_rule.http_access: Destroying... [id=sgr-047be447c0a063982]
            aws_vpc_security_group_egress_rule.all_outbound: Destruction complete after 1s
            aws_vpc_security_group_ingress_rule.http_access: Destruction complete after 1s
            ...
            ...
            ╷
            │ Error: deleting Security Group (sg-028ce48b2794aa041): operation error EC2: DeleteSecurityGroup, https response error StatusCode: 400, RequestID: cd22ee8e-0a7d-4ea8-97f4-2d8da769ee44, api error DependencyViolation: resource sg-028ce48b2794aa041 has a dependent object
            │ 
            │         

Note that you can no longer access EC2 instance because the ingress rules have already been deleted. Not a good situation!!!

# Solution 2
The answer is to create the replacement security group first, and we can do that with the create_before_destroy argument. 
The syntax for the argument is simple. First, I'll place a lifecycle block inside of the aws_security_group resource. 
And then inside the lifecycle block, I'll add the create_before_destroy argument. The value for the argument is true or false.

We want to create our replacement security group first, so I'll set it to true. With our change in place, I'll run terraform apply again. 
Once the plan finishes generation, note that the output is a little bit different. The recreation symbol is now a plus followed by a minus, 
giving us a visual indication of the change. I'll approve the plan. And this time, the apply starts with creating the new resource.

While that's running, I want to mention a few things about create_before_destroy. 

First, when you set create_before_destroy to true, that setting is passed up the dependency chain. 
For example, our security group is dependent on the VPC. So the VPC will also have create_before_destroy set to true. 

This is done to avoid the creation of dependency cycles in the graph. 
You cannot override this behavior, so it's more something you need to plan around if necessary. 

Also, create_before_destroy may fail due to unique naming and identification requirements for resources on a platform. 
If the replacement resource will have the same exact ID or name as the old resource, 
many platforms will throw an error during creation because the resource in question already exists.
You'll need to alter something about the resource to change that identifier before the operation will complete. 

Lastly, the resource being replaced gets flagged as deposed in state after the new resource is created. 
Terraform will attempt to destroy the deposed resource during the same apply run, 
but if it fails for any reason, Terraform will try and destroy it on the next subsequent run.

Add the following lifecycle block in the aws_security_group.main block and the plan and apply

            lifecycle {
                create_before_destroy = true
            }

        $ terraform plan -out m2.tfplan 

        $ terraform apply m2.tfplan [should create the replacement and attach to the EC2 b4 destroying the deposed SG]

            ...
            aws_instance.web: Modifications complete after 2s [id=i-01da9fe929bc9f1da]
            aws_security_group.main (deposed object cdfc1b3e): Destroying... [id=sg-028ce48b2794aa041]
            aws_security_group.main: Destruction complete after 1s
            ...
            ...

# Practical 3
<!-- replace_triggered_by -->
Most of the time when you change a dependent resource, the downstream dependencies will replace themselves as needed. 
For instance, if a newer AMI is returned by a data source, the AWS instance using that AMI will trigger a replacement, since the AMI attribute is not mutable. 

But there are times when the relationship is less obvious, where a change in one resource wouldn't necessarily cause another resource to be replaced, even if that's what you want. 
Instead, you need to express the relationship between those two entities explicitly. 

For instance, you may have an ECS service that you want to be replaced each time a security group rule is updated. 
Or you might want an auto‑scale group to be replaced each time a new version of the application is released. 

To achieve the desired behavior, you can leverage the replace_triggered_by argument in the lifecycle block. 
The argument takes a list of resources or resource attributes that should trigger a replacement. 
Anytime one of those references is updated to a new value, it will trigger a replacement of the current object. 

You can only reference managed resources and not data sources, input variables or local values. 
This is because the replacement is triggered by the planned update action, and only managed resources have update actions. 

To get around this limitation, you can make use of a special resource type called terraform_data. 

        resource "terraform_data" "trigger" {
            input = any_value-type

            triggers_replace = any_value_type
        }

The terraform_data resource is part of the built‑in Terraform provider, and it serves as a replacement for the null resource from the null provider. The resource has two available arguments. 
Input stores the specified value in state and exposes it using the output attribute. 
Triggers_replace stores the given value in state and replaces the terraform_data resource if the value changes. 

We can trigger an arbitrary resource replacement by referencing the terraform_data resource in the replace_triggered_by argument 
of a resource and then supplying a new value for the input argument of the Terraform data block. 

# Solution 3
Let's see this in action with the Taco Wagon configuration. If you'll recall, we wanted the asset cache bucket to be replaced each time the application version is updated. 
We can add this functionality through the use of the terraform_data resource and the replace_triggered_by argument. 

Heading back to VS Code, I'll go into the variables file and add a new variable called application_version. 
This will be updated by the team each time a new version of the application is published. I'll set the type as string and not set a default value. 
Going back to the main.tf, scroll down to the bottom, and I'm going to add the terraform_data resource and give it a name of application_version so we know what it's for. 

Inside the resource block, I'll add the single argument for input and set it to var.application_version. When this resource is created, the input value will be stored in state. 
Now, in the asset cache bucket, I'm going to add a lifecycle block, and inside that block, add the replace_triggered_by argument. 
For the value, I'll specify a list that contains the terraform_data.application_version resource. 

#variable.tf
    variable "application_version" {
        description = "Version of the Taco Wagon application."
        type        = string
    }

#main.tf

    resource "terraform_data" "application_version" {
        input = var.application_version
    }

    In aws_s3_bucket.cache add:

#terraform.tfvars

    application_version = "1.0.0"


Now plan and apply it

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out m2.tfplan

        ...
        ...
        # terraform_data.application_version will be created
        + resource "terraform_data" "application_version" {
            + id     = (known after apply)
            + input  = "1.0.0"
            + output = (known after apply)
            }

        Plan: 1 to add, 0 to change, 0 to destroy.
        ...
        ...

    $ terraform apply m2.tfplan [Nothing but should change but writing the new variable to state]

    $ terraform state show terraform_data.application_version
    
        # terraform_data.application_version:
        resource "terraform_data" "application_version" {
            id     = "98d2930a-c322-5eba-812d-17121b7e07fe"
            input  = "1.0.0"
            output = "1.0.0"
        }   

Now change the value of the application_version variable value to 1.1.0 in terraform.tfvars         

    application_version = "1.1.0"

Run a plan and apply and see the cache s3 bucket slated for replacement and then deleted and recreated

    $ terraform plan -out m2.tfplan

        ...
        ...
        # aws_s3_bucket.cache will be replaced due to changes in replace_triggered_by
        -/+ resource "aws_s3_bucket" "cache" {
            + acceleration_status         = (known after apply)    
        ...
        ...
        }
        ...
        ...

    $ terraform apply m2.tfplan [Nothing but should change but writing the new variable to state]

        aws_s3_bucket.cache: Destroying... [id=taco-wagon-dev-cache-20260612151914133500000002]
        aws_s3_bucket.cache: Destruction complete after 1s
        terraform_data.application_version: Modifying... [id=98d2930a-c322-5eba-812d-17121b7e07fe]
        terraform_data.application_version: Modifications complete after 0s [id=98d2930a-c322-5eba-812d-17121b7e07fe]
        aws_s3_bucket.cache: Creating...
        aws_s3_bucket.cache: Creation complete after 5s [id=taco-wagon-dev-cache-20260612180836756200000001]    

# Modify Lifecycle Behavior
There are some very important resources that should be safeguarded from accidental deletion. 
There are several ways to accomplish this goal. Most cloud platforms have a way for you to place a resource lock that prevents deletion or alteration of a resource. 
You can do so using:

    - Resource lock on platforms
    - Proper RBAC applied
    - Terraform's 'prevent_destroy' argument

# Practical 4
<!-- prevent_destroy -->
Using and setting prevent_destroy to true in the lifecycle block prevents destruction or recreation actions on that resource. 
The resource can still be updated in place, but if a change requires recreation, it will be blocked. 
Prevent_destroy should be used sparingly and as part of a larger resource management effort. 
Anyone with access to the Terraform configuration and the environment can change the prevent_destroy value to false. 
But at least that change becomes more deliberate than accidentally recreating a production database because you didn't realize that updating the Postgres version couldn't be done in place. 

Part of the requirements for the Taco Wagon team application is to prevent the logging bucket from being destroyed accidentally. 

In main.tf aadd the below to aws_s3_bucket.logging block

        lifecycle {
            prevent_destroy = true
        }

Now run a plan:

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out m2.tfplan [manually try to replace the logging bucket. Quicker than running apply]
        ...
        ...     
        Plan: 1 to add, 0 to change, 1 to destroy.
        ╷
        │ Error: Instance cannot be destroyed
        │ 
        │   on main.tf line 120:
        │  120: resource "aws_s3_bucket" "logging" {
            ..
            }
            ..
            ..           

<!-- ignore_changes -->
Some tips to keep in mind about ignore_chnages;
- Accepts a list of attributes to ignore
- Uses the argument values of the resources during initial creation
- After creation values are ignore
- A recreation uses the attribute values stored in the resource block
- Although new values are not applied, they are still recorded in state

The Taco Wagon team will be using organization policies to manage EC2 tags, so they would like you to set up Terraform to ignore changes to the tags attribute for EC2 instances. 
I'm going to run the PowerShell script update‑ec2‑tags. It will use the outputs from the configuration and the AWS CLI to add a Team tag to Taco Wagon. 
There we go. There's also a Bash version of the script if you prefer. 

    $ ls -ls update-ec2-tags.sh

        4 -rw-rw-r--. 1 cogu cogu 859 Jun 12 10:05 update-ec2-tags.sh

    $ chmod u+x update-ec2-tags.sh

    $ ls -ls update-ec2-tags.sh

        4 -rwxrw-r--. 1 cogu cogu 859 Jun 12 10:05 update-ec2-tags.sh

    $ ./update-ec2-tags.sh 

        Found instance: i-01da9fe929bc9f1da in region: us-east-1
        Successfully added tag Team='Taco Wagon' to instance i-01da9fe929bc9f1da

Go to the console and verify the new ECE tag ==> "Team" : "Taco Wagon"

Before I make any changes to the configuration, I'm going to run a terraform plan and see what the results would be. 

    $ terraform plan -out m2.tfplan [note that the  new tags will be remove by terraform as indicated by the red minus sign '-']

        ...
        ...
        # aws_instance.web will be updated in-place
        ~ resource "aws_instance" "web" {
                id                                   = "i-01da9fe929bc9f1da"
            ~ tags                                 = {
                    "Environment" = "dev"
                    "Name"        = "taco-wagon-dev-web"
                - "Team"        = "Taco Wagon" -> null
                }
        ...
        ...
        }

As you might expect, there's one change that comes back in the plan, and the change is to remove that Team tag from the EC2 instance, but that's not what we want. 


In main.tf, I'll add the lifecycle block  to aws_instance.web and inside of there, the ignore_changes argument. 
I'll set it to a list that includes tags and run a plan again. 

    lifecycle {
        ignore_changes = [tags]
    }


    $ terraform plan -out m2.tfplan [the resulting plan should say No Changes]