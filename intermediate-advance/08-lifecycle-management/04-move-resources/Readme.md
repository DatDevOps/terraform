<!-- Moving Resources -->

As your infrastructure evolves, so will the code supporting it. 
That may include refactoring existing code, creating modules for common deployment patterns or breaking up large configurations into more manageable chunks. 
While your code may change, you'll likely want to leave your running infrastructure undisturbed and serving the applications it was deployed for. 

Let's discuss what it means to move a resource and how that affects Terraform's view of the world. 
There are two kinds of resource moves you may undertake with Terraform code:

    - moving a resource within a configuration 

    - moving it to a different configuration. 

Let's start with moving a resource within a configuration. By moving, I mean changing the address of an existing resource. 
Every resource in a configuration has a unique address, sometimes called its identifier. 

Resources in the root module take the form of 
    -   resource_type.name
Resources in child modules prepend module: 
    -   module.name  

Changing the name label of a resource or moving it to a different module in the same configuration would be considered a resource move. 
Let's use a simple example. I have an aws_s3_bucket with the name label main. 
I want to change the name label to logging to better describe the purpose of the bucket. 
After making the change, if I run a terraform plan, it will attempt to destroy the existing S3 bucket and create a new one. 
Why? Bear in mind, Terraform is always trying to make state match what's in your configuration. 
When you run terraform plan, Terraform will see that there's an entry in state or an S3 bucket with the address aws_s3_bucket.main. But there's no corresponding resource block in the configuration. 
To make state match the config, Terraform will plan to destroy the bucket. It also sees that there's a new resource block with the address aws_s3_bucket.logging. 
To make state match the config, Terraform will plan to create the new bucket. 
As the configuration stands now, Terraform had no way of knowing your intention was simply to change the address and not recreate the bucket. 
We'll see how to express that intent declaratively in a moment.

# Moving within a Configuration
To let Terraform know about our intention to change resource addresses, we can use the moved block. The block syntax is very simple. 
It uses the keyword moved and doesn't take any block labels. Inside the block, it only takes two arguments. 
The from argument is the address the resource was originally located at. And the to is the new address of the resource. 
That's it. Moved blocks go in your root module or in a child module. 
This lets module authors express declaratively when resources have been moved or renamed without the module consumer having to do anything. 
The moved block should go in the module where the resource is moving from. 
In terms of workflow, you first update the resource blocks in your configuration and then add the moved blocks. 
Once the changes are complete, running terraform plan will show you the changes Terraform will make to state to complete the move. 
If everything looks good, then you can apply the change. 
After the move is complete, you can delete the moved blocks or leave them for historical purposes. 
The presence of moved blocks will not impact future Terraform runs. 
For module authors, I recommend keeping moved blocks in their own file and maintaining them until the next major version of the module.

# Practical-1 Moving within a Configuration

Here we will start with the sopes_saloon configuration that creates a vpc and associated resources in main.tf and refactor it to use a vpc module with new naming for it and associated resources without deleting the any of the resource

    $ cd /08-lifecycle-management/04-move-resources/before-moving resources/sopes_saloon

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out m4.tfplan

    $ terraform apply m4.tfplan

Now see 08-lifecycle-management/04-move-resources/after-moving-resources/sopes_saloon/modules/vpc/main.tf  and output.tf for the refactor and move command with new names and associated resource moves to

Modify main.tf and output.tf in /08-lifecycle-management/04-move-resources/before-moving resources/sopes_saloon to match and then run below. If all is good, there should be no chnages when you run a plan 

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out m4.tfplan
        ...
        ...    
        Plan: 0 to add, 0 to change, 0 to destroy
        ...
        ...

    $ terraform apply m4.tfplan [approve the plan if it shows zero addition, chnages, or destroy]


# Resource Migration Options
Moving resources to another configuration or outside of Terraform's management is a slightly different challenge than refactoring within a root module. 
There are two options you can proceed with:
    -   imperative option
    -   declarative. 

The imperative option involves using either the command terraform state mv or terraform state rm. 
Terraform state mv moves a resource from a source location to a destination, and it is a precursor to the moved block. 
The source argument corresponds to the from argument, and the destination argument is the same as the to argument in the block. 
The command will update state with the change, but you still need to make the actual code change before you run a terraform plan or apply.

#move resources from old to new address

    $ terraform state mv <SRC> <DEST>

    $ terraform state mv aws_instance.main aws_instance.web

#move to another configuration

    $ terraform state mv -state-out=../dest-config/terraform.tfstate  [this is local state]

If you're not using local state, you actually need to run:
    -   terraform state pull to grab the current state from the remote location
    -   terraform state mv command to move the resource, and then use the 
    -   terraform state push command to upload the new version of state. 

All of this state manipulation outside of the regular workflow makes me a little twitchy, so I don't recommend it. 


The terraform state rm command is used when you want to remove an object from state without destroying the real resource. 
The command is terraform state rm and the address of the resource you want to remove. 
The command simply removes it from state, and you still have to remove the actual resource block before running a terraform plan or apply. 
Both the terraform state mv and rm commands make changes directly to state outside of the standard Terraform workflow. 

    $ terraform  state rm <ADDR>

So what are your declarative options? 
If you're simply removing a resource from management by Terraform, you can use the removed block. 
The syntax is very straightforward. It uses the removed keyword and no block labels. 
Inside the block, you'll add the from argument set to the address of the resource you're removing. 
To prevent the resource from being destroyed, you need to add a lifecycle block with the argument destroy set to false. 
Once you add the removed block and delete the corresponding resource block, you can run terraform plan to review the changes and then apply them. 

    #remove.tf

    removed {
        from = resource_address

        lifecycle {
            destroy = false
        }
    }

If you're looking to migrate a resource to a new configuration, then the process still uses the removed block in the source configuration and then the import block in the destination configuration. 
In the destination configuration, you can add the import block and then copy over the resource block from the source configuration, modifying any argument values as necessary. 
You can inspect the source configuration state to get the ID of the resource for the import block. 
In the source configuration, you'll add the removed block and remove the resource block. 
On each configuration, you'll run a terraform plan and apply, and the resource will be successfully moved over. 
And you don't have to do it a single resource at a time. You can move as many resources at once as you want. 
Overall, I recommend using the declarative process. 
As it enshrines in code what changed, it allows for multiple resource moves in one operation, and it provides feedback through an execution plan before the changes are made.    

#source-config/main.tf

    resource "aws_instance" "main"{
        instance_type = "t3.micro"
        ami           = var.ami_id

        tags = {
            Name = "globo-web-app"
        }
    }

    removed {
        from = "aws_instance.web"
        lifecycle{
            destroy = false
        }
    }    


#destination-config/main.tf

    import {
        to = "aws_instance.web"
        id = "i-123654789"
    }

    resource "aws_instance" "main"{
        instance_type = "t3.micro"
        ami           = var.ami_id

        tags = {
            Name = "globo-web-app"
        }
    }


# Practical-2 Migrating Resources to a New Configuration
We are going to use the removed and import blocks to migrate the application components of the Sopes Saloon application from Practical-1 to a new configuration. 
What are we going to move? 
- We're going to move the EC2 instance, 
- the security group, and its included security group rules. 

In the variables.tf, I have the necessary input variables, and if we go over to main.tf, I have the necessary provider configuration and locals configured. 
But it doesn't have the resource blocks yet. 
Let's start by getting the new configuration prepared with import blocks. 

Down in the terminal, I'm going to switch to the sopes_saloon directory and run 

    $ terraform output  [copy the output shown below]

    ...
    instance_id                 = "INSTANCE_ID_FROM_OUTPUT"
    security_group_egress_rule  = "SECURITY_GROUP_EGRESS_RULE_ID_FROM_OUTPUT"
    security_group_id           = "SECURITY_GROUP_ID_FROM_OUTPUT"
    security_group_ingress_rule = "SECURITY_GROUP_INGRESS_RULE_ID_FROM_OUTPUT"    
    ...

-   Comment out the resourcs to move to another configuration as shown in after-moving-resources/sopes_saloon/main.tf
-   Add the removed.tf file with the commented resources above to remove as shown in after-moving-resources/sopes_saloon/removed.tf
-   Now copy the commented out code in main.tf of sopes-saloon to main.tf of sopes-saloon-app as shown in the after-moving-resources/sopes_saloon_ap
-   Add import.tf file to sopes-saloon-app as shown in the after-moving-resources/sopes_saloon_app with the associated import sstatement and local variablecopied from the sopes-saloon output command above
-   Add the  corresponding values to terraform.tfvars as shown in the after-moving-resources/sopes_saloon_app
    
If you really wanted to get fancy, you could use the Terraform remote state data source to pull these values dynamically, but I'll leave that as a challenge for you. 
That should do it for the new configuration, so let's try and import the resources. 

I'll switch to the sopes_saloon_app directory and run a terraform init. 

    $ terraform init

Once the import is complete, we'll technically be managing the resources with two configurations, so this is the type of activity you would want to coordinate with your team. 
Now that the initialization is complete, I'll run a terraform apply and see what the results look like. 

    $ terraform apply

After a few moments, it tells me it's going to import four items and change one. 

If I scroll all the way up through the execution plan to the AWS instance, for whatever reason, 
it wants to set the user_data_replace_on_change property to true, even though that was already set. 
That's not a problem, so I'll approve the import. 
Once that's complete, we can start adding our removed blocks. 

The import completed successfully, so now we need to remove those resources from the sopes_saloon config.

Now do this:

-   Add the removed.tf file with the commented resources above to remove as shown in after-moving-resources/sopes_saloon/removed.tf


Okay, with those removed blocks in place, we can now remove the resource blocks from the main.tf. 
I'll can delete all four of the blocks and the data source. There's still a little bit of cleanup to do. 
Our outputs reference the resources we just deleted, so I'll go into the outputs.tf and remove all of those output blocks. 
Lastly, I'll go into the variables.tf and remove the input variable instance_type since it's no longer used. 
That's not strictly necessary, but it does make the code a bit cleaner. With those changes in place, 

I'll pull the terminal back up and change to the sopes_saloon directory. From there, I'll run a terraform apply under sope-saloon. 

    $ terraform apply

And once it completes the execution plan, it should tell us that it's going to remove the four items from state without destroying the actual resources. 
Sure enough, that is what it says, so I'll approve it. Because we're simply altering state, the changes should happen very quickly, and we're done. 
We have successfully moved resources from one configuration to another without disrupting the actual resources themselves. 
