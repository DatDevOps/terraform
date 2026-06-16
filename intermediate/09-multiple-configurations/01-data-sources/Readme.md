<!-- Data sources in Terraform -->

When you first adopt Terraform, you'll likely be dealing with a single configuration that expands and evolves over time, growing ever bigger and more complicated. 
At some point, you may decide to break up that configuration based on separation of concerns, ease of maintainability or a need to speed up development cycles. 
Whatever the reason, managing multiple related configurations relies on passing information between those configurations, and that is what this course is all about.

You can get data into Terraform by:
    -   Input variable
    -   File functions
    -   Data sources

When writing your Terraform configuration, there are a few ways to bring in external information. 
You can use input variables and pass information to the configuration at runtime. 
You can use one of the many file functions to pull in information

You can leverage data sources from a provider plug‑in. 
Honestly, you'll probably end up using all three of these in some combination, but we're going to focus on data sources. 
A data source in Terraform is a provider‑defined object that allows you to query for information from the platform or service the provider is supporting. 
You aren't creating anything, but simply asking for information you want to use in your configuration. You can think of a data source like a read‑only resource. 
    -   Defined in providers
    -   Used to query external information
    -   Stored in state
    -   Data source attributes are refreshed during a Terraform Plan


#syntax

    data "<data_source_type>" "<name_label>" {
        #Data source argument

        count = <integer>
        for_each = map | <set>

        provider = <provider_alias>

        depends_on = [<objkect_references>, ...]

        lifecycle {
            precondition {}
            postcondition {}
        }
    }


<!-- Generative Data Sources -->
Most data sources are about querying for information from an external platform, but there are a few data source types that don't actually query a platform 
but instead generate an internal document for the Terraform configuration to use. What do I mean? Let me give a few examples. 

1. One example is the aws_iam_policy_document data source. You might think it retrieves an IAM policy from your AWS account, but it does not. 
Instead, it generates an IAM policy document in the proper JSON format, which you can then use with the AWS IAM policy resource to create the actual policy. 
While it is possible to generate the proper JSON for the policy on your own, the aws_iam_policy_document data source makes it a lot easier and ensures all the proper fields are in place. 

2. Another example is the cloudinit_config data source from the cloudinit provider. In a similar vein to the policy document data source, 
the cloudinit_config data source helps you craft a cloud‑init document to be used by a server during startup. 
You're not querying an external platform or service but rather using the construct of a data source to correctly format and generate a document to be used by another resource. 
While you could write your own cloud‑init document manually, using the data source ensures that it will be in the correct format, and it's easier than writing YAML manually.

3. You could query for the list of availability zones for the region you're currently using in AWS. 

4. You could get the current list of container images from a container registry to use for a Kubernetes deployment, 
   or you could find an existing virtual network and subnets to use for your application deployment. 

   
And that's just a few of many, many ways that data sources are leveraged in Terraform  

As an example, let's say I want to query for information about an existing AWS VPC for the development instance of the Taco Wagon application. 
The data source type I could use is aws_vpcs, which queries for all the VPCs in a region that match the filter or tags that I specify. 
Inside that block, I would provide a filter block or tags associated with that VPC. 
In this case, I would specify application = "taco‑wagon" and environment = "development". 
What I would get back is all VPCs in the current region that have those matching tags.    

    data "aws_vpc" "app_net" {
        tags = {
            application = "taco-wagon"
            environment = "development"
        }
    }

#data source reference

        data.<data_source_type>.<named_label>.<attribute>

    Ex.

        data.aws_vpcs.app_net.ids

# Practicals

    $ cd 09-multiple-configurations/01-data-sources
  
    $ mkdir before-adding-data-source  [create folder to holder code before adding data sources]
    
    $ mkdir after-adding-data-source  [create folder to holder code after adding data sources]
    
    $ cd before-adding-data-source

    $ cp -R ./taco-wago . [copies staring code to base_app from module  directory]

    $ cd ./taco-wagon


First, let's open up the main.tf and scroll down to the subnets. 
They're being deployed using availability zones, and those are passed in as an input variable. That could be somewhat error‑prone, and less dynamic. 
Next, let's scroll down to the aws_instance resource. That one is using an input variable for the AMI that makes the configuration more error‑prone to bad user input, and it restricts its flexibility. 
You have to update the AMI for each region you want to deploy to. 
The instance is also using a heredoc string to pass the startup script to the user_data argument. That's clunky, and it doesn't scale well. 
We should plan to add data sources to replace both of the input variables and the startup script. 

Before we do that, let's deploy things as they are now. 

    $ cp terraform.tfvars.example terraform.tfvars

Run the command in base_app/setup/command.sh [or the command.ps1] in your terminal or cloudshell to get the availability zone and latest AMI

Copy the AMI values and availability zone from the above and replace the corresponding values in terraform.tfvars

    $ terraform init [make sure to  be in /base_app/taco-wagon directory]

    $  terraform fmt --recursive

    $  terraform validate

    $ terraform plan -out m1.tfplan
    
    $ terraform apply m1.tfplan

Now if you successfully deploy the infra as it is. 
Move into after-adding-data-sources directory and copy the taco-wagon from the before-adding-data-sources to after-adding-data-sources

    $ cd ../../after-adding-data-source/

    $ cp -R ../before-adding-data-source/taco_wagon/ .

Now take a close look at the following modified code in main.tf and variable.tf

In my main.tf, I've added the availability zones data source and called it available. 
Scrolling down to the subnets, I've replaced the original availability_zones_input variable with an availability_zones_count variable that takes a number. 

For the availability_zone argument, I've added the data source reference and used the count.index to pick the correct az name from the list. 

Scrolling down to the AMI data source, I placed it just above the aws_instance. For the owners argument, I set it to amazon and most_recent set to true. 
Inside of the filter block, the name is set to name, so we're filtering on the name tag, and the values is set to the name we got from the AWS CLI command with a wildcard in place of the version and date information. 

The data source is used by the EC2 instance. And scrolling down to that, we have the ami argument set to the data source and the id attribute. That's it for the resources. 

Over in the variables.tf, I removed the availability zones and instance AMI ID variables. 
I added a new variable called availability_zones_count and set the type to number. 
You could add additional validation checks here to see if the value is greater than 0 and less than maybe 6. I'll leave that as an exercise for you. 

In the terraform.tfvars, I removed the two variable values that no longer have a corresponding input variable and added a value for availability_zones_count, setting it to 2. With all of these changes in place, we can run a terraform plan. 

        $ terraform init 

        $  terraform fmt --recursive

        $  terraform validate

        $ terraform plan -out m1.tfplan [if no chnages goo but if there are changes, apply with -refresh-only flag as shown below]

            data.cloudinit_config.user_data: Reading...
            data.cloudinit_config.user_data: Read complete after 0s [id=559967925]
            data.aws_availability_zones.available: Reading...
            data.aws_ami.amzn_linux2: Reading...
            ...
            ...

            Plan: 1 to add, 6 to change, 1 to destroy.

                
        $ terraform state list [note that the data sources although pulled by the plan are not included in state yet]

            aws_instance.web
            aws_internet_gateway.main
            aws_route_table.public
            aws_route_table_association.public[0]
            aws_route_table_association.public[1]
            aws_security_group.web
            aws_subnet.public[0]
            aws_subnet.public[1]
            aws_vpc.main

If I wanted to get my data sources populated without changing the infrastructure, I could run terraform apply with the ‑refresh‑only flag. 
The ‑refresh‑only flag queries all managed resources and data sources and then plans to update state to reflect the latest information for the remote objects. Our refresh apply is going to bring in the data source information, 

        $ terraform apply -refresh-only 

            No changes. Your infrastructure still matches the configuration.

            Terraform has checked that the real remote objects still match the result of your most recent changes, and found no differences.

            Would you like to update the Terraform state to reflect these detected changes?
            Terraform will write these changes to the state without modifying any real infrastructure.
            There is no undo. Only 'yes' will be accepted to confirm.

            Enter a value:         

        $ terraform state list

            data.aws_ami.amzn_linux2
            data.aws_availability_zones.available
            data.cloudinit_config.user_data
            aws_instance.web
            aws_internet_gateway.main
            aws_route_table.public
            aws_route_table_association.public[0]
            aws_route_table_association.public[1]
            aws_security_group.web
            aws_subnet.public[0]
            aws_subnet.public[1]
            aws_vpc.main

        $ terraform apply m1.tfplan