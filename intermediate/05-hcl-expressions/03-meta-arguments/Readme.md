<!-- Meta-arguments -->

# Looping constructs
Uses to create multiple resources without repeating your code. Uses the software principle of DRY
To achieve this goal we use the loop construct:
    - count: 
    - for_each: 
    - Dynamic Blocks

Both count and for_each are referred to as meta‑arguments, meaning that they're an argument that tells Terraform how to build a configuration, 
and it's not a value that's passed to the target service or platform through the provider.     

1. Count:The count meta‑argument can be used with resource, data, and module blocks. The argument takes a non‑negative integer as a value. 
It works with resource, data, and module blocks
The value doesn't have to be a literal expression, it can come from an input variable, local value, or from a conditional statement. 
Terraform will create the number of instances equal to the integer you provide. Interestingly, count does accept 0 as a value, 
so you can choose to create 0 instances. This allows you to leverage conditional statements to make the provisioning of objects optional.
Within the object where you use the count meta‑argument, you have access to a special expression, count.index. The expression will evaluate 
to the current iteration of the object that Terraform is processing. The numbering starts at 0, so a count of 3 will result in three instances with indexes 0, 1, and 2. 

E.G

    #creating resource with count
    resource "aws_subnet" "public" {
        count = var.public_subnet_count
        cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
        tags = {
            Name = "globo-web-${count.index + 1}
        }
    }

    # referencing resources created with count uses the syntax: <resource_type>.<named_label>[count_index].<attribute>
    aws_subnet.public[1].arn # returns the arn of a single instance or the second public subnet arn
    aws_subnet.public[*].arn # returns the arn of all instances

2. for_each: When you need to create multiple instances of an object that are distinct, the for_each meta‑argument has you covered. 
Just like count, it works with resource, data, and module blocks. Unlike count, it doesn't use an integer. Instead, it can accept a map or a set of strings.
To create a zero number of instances, you can pass an empty map or set
Terraform will create a number of instances equal to the number of keys in a map or elements in a set. If you want to create 0 instances, you can use an 
empty map or an empty set. Rather than having the count.index available, the for_each argument has two special expressions. 
Each.key references the key of the map for that instance, and each.value references the matching value. 

E.G.

    #creating resource with for_each

        resource "aws_s3_object" "taco_toppings" {
            for_each = {
                cheese  "cheese.png"
                lettuce  "lettuce.png"
            }

            key = each.value
            source = "./${each.value}
            tags = {
                Name =  each.key
            }
        }

    #referencing resource with for_each uses the syntax: <resource_type>.<named_label>[key].<attribute>

        aws_s3_object.taco_toppings["cheese"].id  # returns a single instance

The for_each key‑based reference model makes it safer to alter that underlying data structure without accidentally forcing resource creation.

What do I mean by that? Let's consider the following in 03-meta-arguments/examples 

    provider "aws" {
    region = "us-east-1"
    }

    locals {
    bucket_list = ["logs","data","backups"]
    }

    resource "aws_s3_bucket" "use_count" {
    count = length(local.bucket_list)
    bucket_prefix = local.bucket_list[count.index]
    }    

Deploy 03-meta-arguments/examples/count_expression/main.tf
Run a terraform state list so you can see that they exist.
There are my three buckets with indexes 0, 1, and 2. Now, what happens if I update the list to include a new entry, telemetry like this ["logs","telemetry", "data","backups"], that I put between logs and data? If I run a terraform plan and the plan has been generated, it will tell me it needs to destroy the data and backup buckets and then create three new buckets called telemetry, data, and backups. From Terraform's point of view, the name prefix for index 1 and 2 changed, and that forces a bucket recreation. If you apply this change, your data and backups are gone, and you might be too. 

What if we did this with for_each? 

    provider "aws" {
    region = "us-east-1"
    }

    locals {
    bucket_list = ["logs","data","backups"]
    }

    resource "aws_s3_bucket" "use_foreach" {
    for_each = toset(local.bucket_list)
    bucket_prefix = each.value
    }  

I've destroyed the buckets created with count and recreated them using for_each. 
Deploy 03-meta-arguments/examples/for_each_expression/main.tf
Run a terraform state list so you can see that they exist.
I'll run a terraform state list to show the three buckets that have been created. 
There they are, and now instead of an index, each is using an element from the list as its key. 
I'll add the telemetry entry again and run a terraform plan to see what will happen.
Terraform plans to just create the one new bucket for telemetry. All the other keys are already present, so no other changes are needed.     

When you're deciding between using count or for_each, think about how the underlying data structure might change over time and choose the one that provides the most stability and reliability for your use case.

3. Dynamic blocks: While for_each and count are great for creating multiple instances of the top‑level blocks, resource data, and module, 
dynamic blocks are used to create the nested blocks inside of resources. Syntax is  shown below:

    # genral syntax
    dynamic "<block_type>"{
        for_each = <map> or <list>
        iterator = <string>
        content{
            <block contents>
        }
    }
    
    e.g.

    resource "aws_instance" "web"{
        #...

        dynamic "ebs_block_device"{
            for_each = local.block_devices
            iterator = "ebs"
            content{
                device_name = ebs.key
                volume_type = ebs.value.volume_type
                volume_size = ebs.value.volume_size
            }
        }
    }

Dynamic blocks are useful, but they can also make your code harder to read and a little more brittle during updates. HashiCorp recommends using dynamic blocks sparingly, if at all.

# Practicals
- make the number of public subnets configurable and dynamic using an input variable value. 
- add S3 buckets for logs, app data, and backups. We'd also like to allow for additional bucket creation using an input variable. 
- dynamically generate ingress rules using a local value that adds a new rule that allows port 8443 for production and 443 for all other environments

Now:

    $ cd 05-hcl-expressions/03-meta-arguments [move into module directory]

    $ cp -R  05-hcl-expressions/02-template-conditionals/base_app . [ copies base_app from previous module 2 to module 3 directory]
    
    $ rm -rf m2.tfplan [deletes the plan generated from the previous module]

Study these main.tf configurations, terraform.tfvars, variable.tf
in the previous module - 05-hcl-expressions/02-template-conditionals/base_app

Now study the main.tf with the added code and comment code that was replaced, the new variables added in variable.tf, variable value in terraform.tfvars in current module  to see the implementations of all
the above requirements

After understanding the additions, run the below: 

    $ terraform fmt 

    $ terraform validate

    $ terraform plan -out m3.tfplan

Now check the security group to see that the  dynamic block workked as expected, the subnets that the index is 0-2,
public access blocked reources shuld have four items    

    $ terraform apply m3.tfplan
    
    $ terraform destroy
