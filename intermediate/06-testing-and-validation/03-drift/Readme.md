<!-- Infrastructure drift and Validation -->

# Current Infrastructure Validation
Terraform is meant to manage the full lifecycle of your infrastructure, not just the initial deployment, 
but the ongoing management and changes that infrastructure inevitably goes through right up to its retirement. 
Ideally, Terraform will handle all of the changes in your environments, but we all know that's not always the case.  
When we talk about drift, we mean that the environment you're managing no longer matches the desired state described by your configuration. 
There are three kinds of drift, two of which Terraform can deal with by itself, and one that may involve an outside tool or script. 

The first kind of drift has to do with one‑time changes made through an external tool or manual process. 
Think of an instance size being changed through the EC2 console. The next time you run a terraform plan, 
it will perform a state refresh and detect that the instance size has changed. 
By default, Terraform will plan to undo that change, making the instance match your desired state. What you choose to do will depend on why the change was made. 
Perhaps the instance type was increased in size through the AWS CLI as part of emergency maintenance when a spike hit the application and it needed the excess capacity. 
The spike is now over, and you can let Terraform change it back to its desired size. Run a terraform apply, it will do exactly that. 

What if the change needs to be permanent? The spike isn't going away because your service was featured on the front page of Hacker News. 
In that case, you can update your Terraform configuration to match the current environment. 
However, when you make that change, your Terraform state is still incorrect, holding the previous instance type. 

To amend the state to reflect reality, you can run a terraform plan with the '‑refresh‑only' flag. 
The ‑refresh‑only flag for plan and apply indicates that Terraform should refresh the state data and write any updates back to persistent storage. 
It does not evaluate the contents of your configuration or compare it to state. It simply updates persistent state to match reality. 

The second kind of drift has to do with automatic changes being made by another system. 
For instance, you may be using an external tool to manage the tags of your resources in AWS. 
Each time the external tool runs, it updates the tags for all the resources. Then the next time Terraform runs, it wants to revert all those changes. 
It's a circular battle that no one wins. The solution is to take Terraform out of the mix for that portion of the resource. 

Inside the lifecycle block is the ignore_changes argument, which takes a list of attributes that Terraform should ignore changes to. 
When Terraform first creates the resource, it will set the attributes as you define, but on all subsequent runs, it will no longer compare the actual values to what's in the configuration/attributes. 
If we apply this to the tags attribute, Terraform and the external tag tool will stop butting heads, and both can manage different aspects of the same resource. 

The third kind of drift occurs when new resources are added to an environment that's managed by Terraform. 
Think of an extra subnet being added to a VPC or a new namespace being added to a managed Kubernetes cluster. Terraform does not know about these new resources and, thus, cannot account for them or their attributes.
However, if you were to destroy the VPC or Kubernetes cluster, you would also be destroying these resources. 
Terraform alone can struggle to detect these new resources when they're introduced or if they're managed by a different Terraform configuration. 
You might turn to a third‑party tool to check, although maybe we could do something with continuous validation. 
As we've seen with our previous validation options, they only execute when Terraform is performing a plan or apply operation, which means Terraform is only validating that the environment matches your configuration during those operations. 
The rest of the time, Terraform is blissfully unaware of what's happening to the infrastructure. 
The idea behind continuous validation is to run Terraform on a scheduled, periodic basis to validate that your environment continues to match what's described by your code and to alert when it does not. 
You can perform continuous validation by scheduling a regular terraform plan and inspecting the generated results. I
If no changes are required, then your environment remains valid, at least as far as Terraform is concerned.

# Using the Check Block

Running continuous validation means that your pre‑ and postconditions will be checked on each plan run. 
When one of those conditions fails, the whole process stops, which means you aren't checking the entirety of your environment. 
It also means that you are only checking for the assumptions and guarantees you want it to make at creation and update time. 

The terraform check block is intended to provide a way to perform validation that's not tied to a specific resource and does not interrupt a run. 
The check block is a top‑level block in Terraform, meaning that it isn't nested inside another block. 
The check block is evaluated during 'plan' and 'apply' as the last step of the operation. 
Each check block has one or more assertions. Each assertion is checked, and if one fails, Terraform reports a warning and continues the rest of the run. 

That means check block validations are non‑disruptive. Let's dig into the syntax. 

#check.tf

    check "<name_label>" {
        assert{
            condition = true | false
            #although the key is error_message, it does not throw an error but a warning
            error_message = "full sentence for warning
        }

        data "<type>" "<name>"{
            #...
        }
    }


In addition to one or more assert blocks, you can also include nested data source blocks, and this is pretty interesting. 
Rather than defining a data source at the top level of the configuration, you can define a data source inside the check block, and it's only available within the scope of that check block. 
Since check blocks are processed last, the nested data source can reference resources and values generated elsewhere in the configuration. 
If the nested data source block fails for some reason, it's reported as a warning in the Terraform run. 
Even though the data source is nested, it still needs to have a unique identifier, so the combination of the data source type and name have to be unique within the module. 
That's because it's stored in state using the identifier. Just like a top‑level data block, the nested data block supports the depends_on and the provider meta‑arguments. 
How might you use a check block in your configuration? Here's a few use cases. 

You can check to make sure that the web service you deploy is available by leveraging an HTTP data source and making sure the status code is 200. 
You can check and make sure that the number of security group rules in a security group matches what's in your configuration. 
This will raise the red flag if someone added another rule outside of Terraform. 
You can check and make sure that your EC2 instances are in a powered‑on state. That's not something Terraform typically checks during a standard plan. 
Or you could check and make sure that the S3 bucket you were given has versioning enabled. 
You might not manage the bucket, but you'd really like to know that versioning is still enabled. 
You could do this with a pre‑ or postcondition too, but that would be disruptive to your runs. 
Check blocks are also leveraged by ACP Terraform and Terraform Enterprise as part of their continuous validation feature. 

# Practicals
- check blocks
 * verify subnets match desired count
 * Check power state of EC2 instance 

# Solution

Now run:

    $ cd 06-testing-and-validation/03-drift

    $ cp -R ../02-pre-post-condition/base_app/ .

    $ cd base_app/

    $ rm -rf m2.tfplan

- create a new check.tf in root module with below content:


    check "subnet_count" {
        data "aws_subnets" "all_subnets" {
            filter {
            name   = "vpc-id"
            values = [aws_vpc.main.id]
            }
        }

        assert {
            condition     = length(data.aws_subnets.all_subnets.ids) == (var.availability_zones * 2)
            error_message = "The number of subnets does not equal the expected count."
        }
    }

    check "ec2_power_status" {
        data "aws_instance" "web" {
            instance_id = aws_instance.web.id
        }

        assert {
            condition     = data.aws_instance.web.instance_state == "running"
            error_message = "The EC2 instance is not in the 'running' state."
        }
    }


Now run:
    
    $ terraform init [if you have not already done so]

    $ terraform fmt

    $ terraform validate

    $ terraform plan -out m3.tfplan [Read *NB below]
   

    $ terraform apply m3.tfplan

    $ terraform destroy

# NB 
Note that the plan shows resources that will be created in addition to the below warning because the resources do not yet exist and some conditions were not met.
Remember we destroyed the resources after completing the last module. If the resource existed, there will be no warning as the resources meet the checks and postconditions

        ..
        ...
        Warning: Check block assertion known after apply
        │ 
        │   on checks.tf line 10, in check "subnet_count":
        │   10:     condition     = length(data.aws_subnets.all_subnets.ids) == (var.availability_zones * 2)
        │     ├────────────────
        │     │ data.aws_subnets.all_subnets.ids is a list of string
        │     │ var.availability_zones is 2
        │ 
        │ The condition could not be evaluated at this time, a result will be known when this plan is applied.
        ╵
        ╷
        │ Warning: Check block assertion known after apply
        │ 
        │   on checks.tf line 21, in check "ec2_power_status":
        │   21:     condition     = data.aws_instance.web.instance_state == "running"
        │     ├────────────────
        │     │ data.aws_instance.web.instance_state is a string
        │ 
        │ The condition could not be evaluated at this time, a result will be known when this plan is applied. 



Introduce some chaos by using the console to stop the EC2 instance and/or create a new subnet.
Then run an plan to see the EC2 postcodition fire with a failure and and the check assertion for subnet count in check.tf with a Warning.

    $ terraform plan -out m3.tfplan

        Plan: 0 to add, 0 to change, 0 to destroy.
        ╷
        │ Warning: Check block assertion failed
        │ 
        │   on checks.tf line 10, in check "subnet_count":
        │   10:     condition     = length(data.aws_subnets.all_subnets.ids) == (var.availability_zones * 2)
        │     ├────────────────
        │     │ data.aws_subnets.all_subnets.ids is list of string with 5 elements
        │     │ var.availability_zones is 2
        │ 
        │ The number of subnets does not equal the expected count.
        ╵
        ╷
        │ Error: Resource postcondition failed
        │ 
        │   on main.tf line 191, in resource "aws_instance" "web":
        │  191:       condition     = self.public_ip != "" && self.public_ip != null
        │     ├────────────────
        │     │ self.public_ip is ""
        │ 
        │ The EC2 instance must have a public IP address.
        ╵

Revert the changes, start EC2 and delete the subnet created using the console 
Run a plan and apply again There should be no errors this time. Hurray🎶

    $ terraform plan -out m3.tfplan
    
    $ terraform apply m3.tfplan
