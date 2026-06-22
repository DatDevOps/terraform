<!-- Import Process Options -->

# Recreating Resources

#Mark a resources for recreation in state

    $ terraform taint ADDR

    $ terraform taint aws_instance.web

#Replace a resource as part of the execution plan

    $ terraform plan –replace="aws_instance.web"

    $ terraform apply –replace="aws_instance.web"

# Import command    
Terraform has two built‑in processes for importing existing resources into Terraform, and we'll examine each one and compare the two options. 
The first option is to use the terraform import command. The command takes two arguments, the desired resource address and the identifier of the resource. 
The identifier is the unique ID of the resource in the target environment, and that identifier is specific to the resource type. 

#command syntax
    $ terraform import [options] ADDR ID

#ADDR - configuration resource identifier
#EX. - aws_vpc.main

#ID - provider specific resource identifier
#EX. - vpc-12345678

#importing the baove existing vpc resource and identifier

    $ terraform import aws_vpc.main vpc-12345678


If we jump over to the documentation for the AWS provider and look at the VPC resource (aws-vpc), down at the bottom is an import section. 
Any resource that can be imported will include an import section in the documentation. 

When you run the terraform import command, Terraform is simply updating the state data with a new entry.
It's adding the resource to state at the address you specify and populating the resource with attributes from the actual resource in your target environment. 
You'll note that it doesn't actually add the resource block to your code. That's up to you. 

    #terraform.tfstate

    {
        "resource":[
            {
                "mode" : "managed"
                "type" : "aws_vpc"
                "name" : "main"
                "instances" : [
                    "id" : "vpc-a01106c2"
                ]
            }
        ]
    }

For each resource you want to add, you'll need to add a resource block to your code and populate it with arguments that match the existing attributes of the resource in your target environment. 
Then you'll run a terraform plan and see if any changes are required. If you've done everything correctly, you should see no changes required. 
If you do see changes required for that resource, you'll need to update your code and try again until no changes are needed.


    #main.tf

    resource "aws_vpc" "main" {
        cidr_block  = var.vpc_cidr
        enable_dns_support = true

        tags = {
            Name = var.vpc_name
        }
    }



This is the older imperative process of importing resources with the import command. 
Terraform 1.5 introduced a declarative process that uses the import block. Let's take a look at that. 
The syntax for the import block is incredibly simple. The keyword is import, and it doesn't take any block labels.
Inside the block are two required arguments, the to and ID. The to is equivalent to the address in the import command, and the ID is equivalent to the identifier in the import command. 
The block also supports two meta‑arguments. The provider argument lets you specify which instance of a provider should be used to access the resource and query its attributes. 

    #import.tf

    import {
        to = address
        id = identifier
        
        provider = provider_ref
        for_each = map | set(string)
    }

If we jump over to the documentation for the AWS provider and look at the VPC resource (aws-vpc), down at the bottom is an import section. 
That section tells us what the unique identifier is for a VPC as shown below. It's the VPC ID. Any resource that can be imported will include an import section in the documentation. 

    #In Terraform v1.5.0 and later, use an import block to import VPCs using the VPC id. For example:
    
    import {
        to = aws_vpc.test_vpc
        id = "vpc-a01106c2"
    }

The for_each argument allows you to specify multiple instances of a resource and map them back to a single resource block. 
The target resource block identified in the to arguments would also need to implement the for_each argument. 
All resources will need to be of the same type if you choose to use the for_each argument. 
It is possible to declare multiple import blocks in your code, allowing you to import different resource types within the same operation. 
The to argument in the import block specifies a resource address. To create the block for that address, you have two options. 
You can add the resource blocks that match the to argument yourself, or you can have Terraform try and generate the blocks for you. 
What does that process look like? Once you've added your import blocks, you'll run terraform plan. 
If you want Terraform to try and generate the resource blocks for you, you'll need to add the argument ‑generate‑config‑out and set it equal to an empty file path where the blocks should be generated. 
It's currently an experimental feature, so don't be surprised if it gets something wrong with the generated config block.

    $ terraform plan -generate-config-out=generated.tf

If you don't add that argument, then Terraform will simply tell you that the resource blocks are missing and you can add them yourself. 
Either way, when you run a terraform plan, Terraform will do what it always does. It will show you the changes it plans to make to your state data and the target environment. 
If you've done everything correctly, your plan should import the new resources without any changes to them. 
If you do see changes required, then you'll need to update your code and try again until no changes are needed. 
When you're ready to import the resources, you'll run terraform apply, and the resources will be imported. 
So why would you choose one process over the other? The import block was introduced to address several shortcomings in the import command. 

First of all, the import command directly edits state data with no execution plan to review. 
HashiCorp has been trying to reduce any direct edits to state data with the goal of having all operations flow through the standard plan and apply operations. 

Second, the import command only allows you to import a single resource at a time. 
If you have 100 resources, you're going to need to batch up the import commands and wait as each one executes, hoping you didn't mess anything up. 

Third, the import command doesn't create the configuration for you. 
While it is an experimental feature at the moment, letting Terraform create the configuration blocks for your resources helps save time and lower barriers to entry. 
For all of these reasons, the import block will be the preferred method for importing resources into Terraform. 
The import command is still available, at least through major version 1, but I'm certain it will be deprecated in the future.

# Resource Discovery
One of the shortcomings of the import process is that Terraform doesn't go out and find your unmanaged resources for you. 
It's up to you to find out the IDs for each resource that you want to import. 
Depending on how many resources you're planning on importing, that can get onerous really quickly. 

Fortunately, there are some good options out there for you. 
The most DIY solution is to write a discovery script that looks for all the resources in a certain account, subscription, project or resource group. 
I've run into my fair share of folks that are doing exactly that, but it's a lot of work for something that you probably won't do very often. 
There are also several third‑party tools out there that try and help you with discovery. 
The most popular ones I'm aware of are the Azure Export for Terraform tool and Terraformer. 
The Azure Export for Terraform tool is specific to Azure resources only. It can discover, filter, and import your resources all in one workflow. It's actually pretty slick. 

Terraform does something similar for AWS and Google Cloud, but it doesn't appear to be as actively maintained, so your mileage may vary. 
The good news is that in Terraform 1.14, there is now the terraform query command, which is a Terraform native way of doing resource discovery. 
The terraform query command leverages Terraform query files and the new list block type. Query files end in the extension tfquery.hcl. 
When you execute a terraform query command, it will parse all the query files in the current working directory and process the list blocks it finds in those files. 
The terraform query command also has access to objects defined in the root module of the current working directory. 
So you can reference local values, input variables, data sources, and resources inside of your list blocks. 
You can also use the providers defined in your root module to execute the query. 
Let's check out the syntax of an HCL query file. 


        #search.tfquery.hcl

        locals {}

        variable "name" {}

        provider "local_name" {}

        list "list_type" "name_label" {
            provider = provider_ref

            config {
                #List type specific filters
            }

            limit = integer

            include_resource = true | false
        }


At a top level, there are four block types supported. 
You can define local values with a locals block, input variables with a variable block, and provider configurations with a provider block. 
You also have access to the root module if one exists. But you may need to designate locals, variables, and providers that are specific to the query file or might not yet be in the root module. 

The fourth block is the real workhorse, and that's the list block. List blocks are very similar in nature to resource blocks. 
The keyword is list, and then there's two block labels. The first is the list type, and the second is the list block name. 
List types like resource types or data source types are defined by their provider, and not all resources have a corresponding list type yet. 
Inside the list block, you must specify a provider argument along with which provider instance to use. 
That could be a provider instance defined in the root module or one you define in the query file. 
That is the only required argument, and if you don't do anything else, Terraform will query and return all resources in the scope of the provider with that type. 

You'd probably want to filter things down a bit, and that's where the config block comes in. 
Inside the config block, you can specify provider‑specific arguments to filter the results returned by the query. 
You can filter on things like metadata tags, resource groups or resource names. The exact filters available will depend on the provider and the list type. 
You can also limit the total number of results by adding the limit argument. 
By default, Terraform will retrieve up to 100 instances per query block, but you can set that number lower or higher with the limit argument. 

The last available argument is include_resource, which can be set to true or false. 
By default, Terraform only retrieves each instance's identity information, but if you set this field to true, it will also retrieve all the attributes of each instance. 
That could introduce a lot of extra overhead, which affects query performance, so use it sparingly. 
The list block also supports meta‑arguments like for_each and count, but I think that's enough for us to get started.

# Practicals
- Deploy the module infra that consist of a vpc and a single subnet
- use the create-additional-resources.sh or create-additional-resources.ps1 to create a new subnet and an ec2 instance
- query or discover the new resources created with AWS CLIN using the above script
- import the new resources into the terraform config


# Solutions

Deploy the terraform infra with  a VPC and a single subnet

    $ cd ./03-import-resources/burrito_barn

    $ Terraform init

    $ Terraform fmt --recursive

    $ Terraform validate

    $ Terraform plan -out m3.tfplan

    $ Terraform apply m3.tfplan

Let s now create a new subnet and a webserver using the AWS CLI and a script

    $ chmod u+x create-additional-resources.sh 

    $ ls -la create-additional-resources.sh 

        -rwxrw-r--. 1 cogu cogu 3040 Jun 14 07:49 create-additional-resources.sh

    $ ./create-additional-resources.sh 

Let's head over to the AWS docs and see what options are available [https://registry.terraform.io/providers/hashicorp/aws/latest/docs/list-resources/instance]. 
In the AWS docs under Elastic Compute Cloud, there is a separate section called List Resources. 
Inside that section is the aws_instance list type, and it provides us with options for the config block. 
Basically, you can filter on any attribute that is supported by the filter names in the describe‑instances AWS CLI command. 
The script created the EC2 instance with the Team tag set to Burrito Barn, so we can filter on that. 
I do want to mention that not all resources in the AWS provider have an equivalent list resource, and that's true across all the providers. 
The terraform query command is relatively new, and it relies on providers adding support for resource discovery. 
That support will expand and improve over time, but right now, it's somewhat limited. 

Let now query the additional resources created above

- create a new file update.tfquery.hcl and add the content below


    list "aws_instance" "burrito_barn" {
        # Provider to use or provider alias if different from root module provider
        provider = aws
        # 

        # will return instances with tag: Team=BurritoBarn
        config {
            filter {
                name = "tag:Team"
                values = ["BurritoBarn"]
            }
        }
    }

Let query for the EC2 instances:

    $ terraform query -h  [shows you your options]

    $ terraform query [returns 2 instances with tag: Team=BurritoBarn. One created by terraform and the  other by the script]

        list.aws_instance.burrito_barn   account_id=211125717379,id=i-0187ce472426b0ba0,region=us-east-1   burrito-barn-dev-web (i-0187ce472426b0ba0)
        list.aws_instance.burrito_barn   account_id=211125717379,id=i-0b46b20a5760d7238,region=us-east-1   burrito-barn-app (i-0b46b20a5760d7238)    

- Add the below  to the file content update.tfquery.hcl so we can query the subnets


    list "aws_subnet" "public_subnet" {
        provider = aws

        config {
            filter {
                name = "vpc-id"
                values = [aws_vpc.main.id]
            }
        }
    }

Lets query for the subnets:

    $ terraform query [returns 2 instances and subnets with tag: Team=BurritoBarn. One created by terraform and the  other by the script]

        list.aws_subnet.public_subnet   account_id=211125717379,id=subnet-03305a03f10220539,region=us-east-1   burrito-barn-additional-public (subnet-03305a03f10220539)
        list.aws_subnet.public_subnet   account_id=211125717379,id=subnet-011fbcb7aae0ccec7,region=us-east-1   burrito-barn-dev-public-0 (subnet-011fbcb7aae0ccec7)

        list.aws_instance.burrito_barn   account_id=211125717379,id=i-0187ce472426b0ba0,region=us-east-1   burrito-barn-dev-web (i-0187ce472426b0ba0)
        list.aws_instance.burrito_barn   account_id=211125717379,id=i-0b46b20a5760d7238,region=us-east-1   burrito-barn-app (i-0b46b20a5760d7238)  

Take note  of the subnet and EC2 ID's of the new resources

- import the new resources, the subnet and EC instance, into the terraform config     

Create a new file import.tf and add the below content with  the  ec2 instance and subnets ID's for each of the resource

    import {
        id = "i-0187ce472426b0ba0"
        # new resource address to import into
        to = aws_instance.app_server
    }

    import {
        id = "subnet-03305a03f10220539"
        # new resource address to import into
        to = aws_subnet.app_subnet
    }

With our import blocks in place, we could create the resource blocks ourselves, but it's easier to let Terraform do it for us. 
The terraform plan command has an option called generate‑config‑out that is set to a path for a new file. 
When the plan runs, it will look for any import blocks that don't have a corresponding resource block, query the target resources for their attributes, and create the resource blocks in the new file based on those attributes. 
As we'll see in a moment, you end up with very verbose and static blocks. 

Run terraform plan with the generate‑config‑out option set to update.tf. 

    $ terraform plan -generate-config-out="update.tf"

After the file is generated, Terraform will try and run a regular plan. 
More often than not, the result will be an error due to argument conflicts within the new resource blocks. 
Sure enough, we get some errors. Let's look at our new resource blocks. 
When Terraform generates the resource blocks, it pulls in every attribute from the resource and sets basically all of the available arguments. 
You end up with way too much in the block and conflicts like the error was showing. 
I'm going to clean these blocks up a little bit and comment out what some portion created by terraform that we don't need or were hardcoded. 



See the update update.tf file. :

    resource "aws_subnet" "app_subnet" {
        cidr_block                                     = "10.0.10.0/24"
        map_public_ip_on_launch                        = true
        tags = {
            Name = "burrito-barn-additional-public"
        }
        tags_all = {
            Name = "burrito-barn-additional-public"
        }
        vpc_id = aws_vpc.main.id
    }

    # __generated__ by Terraform
    resource "aws_instance" "app_server" {
        ami                                  = nonsensitive(data.aws_ssm_parameter.amzn2_linux.value)
        instance_type                        = var.instance_type
        subnet_id                            = aws_subnet.app_subnet.id
        tags = {
            Environment = var.environment
            Name        = "burrito-barn-app"
            Team        = "BurritoBarn"
        }
        vpc_security_group_ids      = [aws_security_group.main.id]
    }




The next step is to run terraform plan without the generate‑config‑out flag and see what the results look like. 
What we're hoping to see is two resources to be imported and no changes, and if that's exactly what you see, erfect. 

    $ terraform plan -out m3.tfplan

    ...
    ...
    
    Plan: 2 to import, 0 to add, 0 to change, 0 to destroy.
    ...

Now I'll kick off a terraform apply to complete the import process. 
If there had been changes, we could tweak the resource blocks until they match the actual resources exactly. 
I'll approve the generated plan, and the import process is now complete. 
We have successfully imported the unmanaged resources into the Burrito Barn configuration without impacting the actual running resources. 

    $ terraform apply m3.tfplan

Now maybe it's time to set their AWS console access to read‑only.

