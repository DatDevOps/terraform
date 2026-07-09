<!-- Preconditions and Postconditions -->

When you're creating resources in Terraform, you are assuming that certain conditions are true. 
Well, we've already seen how we can use validation blocks to validate our input variables have good input, but what about values that come from resources or data sources? 
In that case, we can use precondition blocks inside the dependent resource to make sure things are copacetic. 

As an example, let's say we're getting an AMI image for an EC2 instance through a data source. Our application requires Ubuntu 22.04 or 24.04 to run properly. 
We can use a precondition block to check the properties of the retrieved AMI and make sure it's the right version. If it's invalid, we can throw an error message and stop the run there. 
If it is valid, we can proceed along in the run. 

Our EC2 instance may also require that a public IP address has been assigned when it launches, so we may want to make sure that the subnet being used has map public IP addresses enabled. 
Once again, if that's not true, we can throw an error and stop the run, and if it is true, we can proceed along with the plan. 

Preconditioned blocks are meant to test assumptions. What if we're the ones creating resources that other resources are reliant on? 
We are making guarantees to those downstream resources that they will get what they need to function. 

How can we test those guarantees to know we're making good on our promise? That's where post‑condition blocks come in. 
To give a couple of examples of testing guarantees, you may want to guarantee that the number of active availability zones is greater than or equal to the requested number of AZ's. 
If it's not, then we should error out and say, hey, we don't have enough availability zones. 
In the data source for the availability zones, we can use a postcondition block to verify that. 
Going back to the EC2 instance example, I may want to verify that my EC2 instance has a public IP address after it's been created. 
I can use a postcondition block to check the properties of the created instance. If there's no public IP, I can stop the run there because I'm not living up to my guarantees made to the downstream dependencies. Ultimately, what you need to bear in mind is that preconditions test assumptions before an object is processed, and postconditions verify guarantees after the object exists.

# using a Preconditions

The precondition block can go inside:
    - the lifecycle block for a resource or a data source.  
    -output block directly since output blocks don't support the lifecycle block. 
    - block includes two arguments.   
        * one or more condition that has to evaluate to true or false 
        - an error message which is printed when the precondition fails. 
    - specify more than one precondition block in a lifecycle or output block, and Terraform will check each precondition you include. 

When does Terraform evaluate these preconditions? The precondition blocks in an object are evaluated before the object itself, and this evaluation occurs both during plan and apply runs. 
During evaluation, the behavior is slightly different for plan. If any of the values in the precondition block are not yet known, the precondition is skipped during plan; otherwise, the condition is processed. During apply, all the values will be known, so all preconditions are processed. When the preconditions are processed, Terraform will check for any failures. If any of the preconditions fail, Terraform will stop processing the configuration and halt the run. 

Dependent resources will not be evaluated. If there are no failures, then the run will continue as normal. 

<!-- Example Preconditions -->

    $ cd 06-testing-and-validation/02-pre-post-condition/examples/preconditions


In the example/precondition/main.tf we've got a single random string resource generating a string that is 16 characters long and has special characters allowed. 
In my output block, I've got a precondition that tests to make sure that there are no special characters in the random string, and that condition should fail. 
I'll run a 'terraform plan' and the precondition doesn't fire because we don't yet have a value for the random string. 
So I'll run a 'terraform apply' and confirm the run. This time, the precondition can run and the condition fails. 

Our random string has special characters in it. If I run a terraform state list, I can see the resource was created successfully. 
But if I run a terraform output, I find that the output was not recorded because the apply failed during the pre‑condition check. 

    $ terraform plan [the precondition doesn't fire because we don't yet have a value for the random string]

    $ terraform apply [the precondition can run because we now know the  value of the random string and the condition fails]

        │ Error: Module output value precondition failed
        │ 
        │   on main.tf line 12, in output "string_val":
        │   12:     condition     = can(regex("^[a-zA-Z0-9]*$", random_string.testing.result))
        │     ├────────────────
        │     │ random_string.testing.result is "?P:)s1eYtW]umvM("


    $ terraform state list [random resources was created and in state]
        
        random_string.testing

    $ terraform output  [no output because the output precondition failed]

        ╷
        │ Warning: No outputs found

You can now update the resource block (examples/preconditions/main.tf) to disable generating special characters and run a plan and apply. It should succeed this time

    resource "random_string" "testing" {
        length  = 16
        special = false
    }

# using a Postconditions    

Preconditions test assumptions, so by extension, postconditions test guarantees. 
These are conditions that must be true after an object is evaluated. The postcondition block can go inside the lifecycle block of a resource or data source. 
Postconditions don't work with outputs. The syntax for a postcondition block is almost exactly the same as the precondition block. It has the same two arguments, condition and error message. 
For the condition argument, one major difference is that a postcondition is checked after an object is evaluated, so you have access to the attributes of the object itself for the condition check. 
These can be referenced using the self keyword. The syntax is self. the attribute you want to reference, like self.public ip for an EC2 instance. 

You can specify multiple postcondition blocks, and Terraform will check each one. 
All blocks will be checked, even if some of them fail, so once again, order of the postcondition blocks doesn't matter. 
The postcondition blocks are evaluated during both plan and apply runs, just like preconditions. 
It doesn't matter if the object holding the postcondition is not being altered by the run, all postcondition blocks are evaluated regardless of what's happening with the containing object. 
If all the values used inside a postcondition are known at plan time, Terraform will check the condition in the block. 
For computed values not known until apply, Terraform will check the condition in the block during apply only. 

When a postcondition fails for an object, Terraform will stop processing the configuration and halt the run. Dependent resources will not be evaluated. 
If there are no failures, the run continues. Let's look at a postcondition example. 

<!-- Example Postconditions -->

    $ cd 06-testing-and-validation/02-pre-post-condition/examples/postconditions

Similar to the precondition example, we have a random string being generated with special characters set to true. 
But this time, we've moved the special characters check to the resource block as a postcondition block. 
The condition has been updated to use the self expression to refer to the result. 
From the terminal, I will run a terraform plan, and that comes back clean since the post condition cannot tell what the value of the string will be. 
I'll run a terraform apply, and once I approve, the run will fail because the generated string has special characters in it. 
If I run terraform state list, it's still created the random string. Running terraform output shows the output was not created because Terraform halted the run.

    $ terraform plan [the postcondition doesn't fire because we don't yet have a value for the random string]

    $ terraform apply [the postcondition can run because we now know the  value of the random string and the condition fails]

        │ Error: Module output value precondition failed
        │ 
        │   on main.tf line 12, in output "string_val":
        │   12:     condition     = can(regex("^[a-zA-Z0-9]*$", random_string.testing.result))
        │     ├────────────────
        │     │ random_string.testing.result is "}*:)s1eYtW]umvM("


    $ terraform state list [random resources was created and in state]
        
        random_string.testing

    $ terraform output  [no output because the output precondition failed]

        ╷
        │ Warning: No outputs found

You can now update the resource block (examples/preconditions/main.tf) to disable generating special characters and run a plan and apply. It should succeed this time

    resource "random_string" "testing" {
        length  = 16
        special = false
    }
# Choosing a Validation

We have introduced three different validation types, variable validation, the precondition, and the postcondition. How do you choose which one to use? 

- Input variable validation: catches potential errors coming from user input. 
For root modules or child modules, you always want to make sure the data entering the module adheres to the proper data type and expected range of values. 
Input variable validation happens earliest in the process and can prevent creation or evaluation of resources when the run as a whole is destined to fail due to bad user input. 

If the value is not coming from an input variable, then it's up to the pre‑ and postconditions. 
As we saw in the two examples, you can actually use pre‑ and postconditions to test for the same issue. 
We checked if our string had special characters at the output level and at the resource level, so, which is correct? 

- Preconditions: are an assumption that you want to check before an object is evaluated. 
It helps future maintainers of the code understand what correct looks like for that object, even if upstream inputs change. 
Maybe we swap our random string resource to an SSM parameter store value. 
The condition isn't about the source of the string, it's about checking whether or not there's special characters in it. 

- Postconditions: on the other hand, are guarantees you're making about that object to other objects in the configuration. 
You're making a promise that this random string will never contain special characters and other objects can rely on that being true. 
Ultimately, your selection of pre‑ and postconditions will depend on the specific use case and how the resources, data sources, and outputs of your module are being consumed. 
It's entirely possible to have one object doing a postcondition check inside a child module, and another object doing a precondition check for the same condition inside the parent module.

# Practicals

<!-- Implementing Preconditions and Postconditions -->
Now it's your chance to add some pre‑ and postconditions to the existing configuration.  

- make sure that the AMI uses an x86_64 architecture 
- the instance type isn't using a Graviton processor. 
- number of availability zones meets or exceeds the number requested. 
- EC2 instance has a public IP address. 

# Solution

In main.tf add this postcondition to data.aws_availability_zones.available under lifecycle

  lifecycle {
    postcondition {
        condition     = length(self.zone_ids) >= var.availability_zones
        error_message = "Not enough availability zones available in region ${var.aws_region} to satisfy the requested number of ${var.availability_zones}."
    }
  }

In main.tf add this pre and post conditions to aws_instance.web under lifecycle

    lifecycle {
        # Ensure the AMI is x86_64 architecture
        precondition {
            condition     = data.aws_ami.amazon_linux.architecture == "x86_64"
            error_message = "The select AMI is not compatible with x86_64 architectures"
        }

        # Make sure the instance type is x86_64 compatible
        precondition {
            condition     = can(regex("^[a-z][0-9]+g[dn]?\\.", var.instance_type)) == false
            error_message = "The selected instance type is not compatible with x86_64 architecture."
        }

        # Make sure the instance has a public IP address
        postcondition {
            condition     = self.public_ip != "" && self.public_ip != null
            error_message = "The EC2 instance must have a public IP address."
        }
    }

Now run:

    $ cd 06-testing-and-validation/02-pre-post-condition

    $ cp -R cp -R ../01-input/base_app .
    
    $ rm -rf m1.tfplan

    $ terraform init [if you have not already done so]

Now run:

    $ terraform fmt

    $ terraform validate

change the number of availability zone to 10 in terraform.tfvars.

    $ terraform plan -out m2.tfplan  [should fail on postcondition because the avaibility  zones are vailable during plan]

        │ 
        │   on main.tf line 26, in data "aws_availability_zones" "available":
        │   26:       condition     = length(self.zone_ids) >= var.availability_zones
        │     ├────────────────
        │     │ self.zone_ids is list of string with 6 elements
        │     │ var.availability_zones is 10    

change the number of availability zone to 2 in terraform.tfvars.

    $ terraform plan -out m2.tfplan  [should now succeed because number postcondition is met]

Now comment replace "subnet_id = aws_subnet.public[0].id" with below:

        subnet_id = aws_subnet.private[0].id

    $ terraform plan -out m2.tfplan  [should fail on postcondition because the instance ip is private instead of public]

Revert you change

    $ terraform plan -out m2.tfplan  [should now succeed because number postcondition is met]

    $ terraform apply m2.tfplan

    $ terraform destroy



















Let's head over to VS Code and do the first one together. Over in VS Code, I've got the maint.tf open, and we'll start with a precondition for our EC2 instance. We want to make sure that the AMI selected uses an x86.64 architecture, so I'll add a lifecycle block and then a precondition block inside. For the condition, I want to get the architecture property from the AMI data source higher up in the configuration, and I want to make sure that it's equal to x86.64. For the error message, I'll simply say that the desired architecture is x86.64 and the provided AMI has the listed architecture. And here I'll use interpolation to print out what the architecture value provided was. This will make it easier for the end user to troubleshoot. All right, that's the first precondition. My challenge to you is to fulfill the other requirements. There are comment placeholders where you need to add blocks. When we come back, we can check out my solution and test the deployment. Okay, welcome back. We were already in the AWS instance resource, so let's see what I added. We've got another precondition here that checks which instance type is being used and makes sure it isn't one of the Graviton models. Those have g in them, sometimes followed by a d or an n. That's what the regular expression is checking for. After that, we have a postcondition check, and this one is accessing the public IP attribute using self.public_ip and making sure that it isn't null or an empty string. Scrolling up to the availability_zones data source, there is a postcondition check here that makes sure that the list of AZ zone IDs is greater than or equal to the requested number of availability zones. Why don't we test a few of these, starting with the AZ postcondition. Before we had zones set to 2, and we're using us‑east‑1, which does have a lot of zones, so let's set it to 10 just to make sure it doesn't have enough. I'll run a terraform plan, and after a few moments, we get back a postcondition error. That's because Terraform refreshes the availability zone data source during plan, and it got back six zones. We asked for 10, so we got an error. Cool, let's see a condition fail during apply. I'll change the availability_zones back to 2. And then going into the main.tf, I'm going to change the subnet association for the instance to a private subnet. Now it won't get a public IP address. Down in the terminal, I'll run a terraform apply, and once it's done generating the plan, I'll approve it. Actually provisioning all the resources is going to take a few minutes, so I'll jump ahead to when it completes. As predicted, the run fails during the postcondition check since the public IP attribute is an empty string. If we check out the contents of state, it looks like everything was created because the EC2 instance was at the end of the dependency graph. I'll change that subnet value back to public and run one more terraform apply. All of our infrastructure is there, but the EC2 instance needs to be recreated to change subnets. I'll approve the plan and jump forward to when it finishes. Our final apply completed successfully. We passed all the pre‑ and postcondition checks. Take a few moments and see if you can get the other conditions to fail. When you're done, make sure to tear everything down so you stop paying for it. We have successfully added pre‑ and postconditions to our configuration to verify assumptions and check guarantees.

