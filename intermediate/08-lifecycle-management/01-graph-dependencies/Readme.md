<!-- Resource Graph and Dependencies -->

# Resource Lifecycles
Terraform aims to manage the full lifecycle of your infrastructure, from its initial creation, 
through its multiple updates and modifications, right up to its eventual replacement or retirement. 

While Terraform does have a standard workflow and order of operations for all of your managed resources, sometimes the defaults just don't fit the bill. 
So what do we mean by the lifecycle of resources? We'll start at the single resource level and expand it to more complete configurations. 
The lifecycle of any given resource starts with its initial configuration or creation, depending on whether we're talking about physical or virtual resources. 
The initial creation or configuration can happen through the CLI, UI or through an API controlled by software like Terraform. 
Ideally, we'd like to start with Terraform, but we all know that's not always the case. 

Over the course of the resource's lifetime, it will need to be modified and updated. 
Sometimes those changes can be made in place, and sometimes the resource needs to be recreated. 
It all depends on what kind of attribute is being changed. 
Again, we'd like to manage these changes with Terraform, but sometimes you may have other services like Ansible or Argo CD or some other configuration management tool. 

All good things must come to an end, and eventually a resource will be retired or removed from management. 
We want to handle this removal gracefully and deliberately. All managed resources will follow this essential lifecycle. 
If you're using Terraform as part of your infrastructure management, it translates to the standard Terraform operations of create, update, recreate, and destroy. 

Beyond those four core actions, there are a few less common operations to consider. 
If your resource wasn't created by Terraform and you'd like to bring it under management, Terraform has the facility to discover and import resources into a configuration. 
There may also be occasions where you need to change the identifier of a managed resource, either moving it within a configuration or across configurations. 
Terraform includes both imperative and declarative processes for managing such a migration. You may also run into situations where you no longer wish to manage a resource with Terraform. 
Sad, but true. In those cases, Terraform includes a graceful way to remove the resource from Terraform state without impacting the actual resource.


# Resource Graph in Terraform
Part of understanding Terraform's management of resources is understanding how it evaluates a configuration and determines what actions to take and in what order. 
When you execute a Terraform plan, in the background, Terraform creates an acyclic graph of your configuration. It starts by identifying each resource and creating a node. 
Each node is linked to other nodes based off of references. Terraform uses those references to build out a graph of dependencies. 

    # Terraform Plan identifies all resources

                A       B       C       D       E       F       G


    # It then proceeds to create a resource graph

                B          D      F
            /       \      |
            |       |      |
            |       |      |            
            A       C      E           
            |
            |
            G

Resources at the top level can be deployed first and in parallel [B, D, F]. Dependent resources at the next level can be deployed afterwards [A, D, E], the [G] and so forth. 

Each branch of the graph is evaluated separately to increase parallelism. 
Based on these nodes and their relationship, Terraform starts at the root node and walks the graph to figure out dependencies, required actions, and order of operations. 
Influencing this graph, the relationships and actions is what lifecycle management is all about. 

Here's a more concrete example. The code on the left shows an AWS VPC and two AWS subnets, both referencing the VPC. 

            resource "aws_vpc" "main"{
               ##
               ...               
            }

            resource "aws_subnet" "pub1"{
                
                vpc_id = aws_vpc.main.id 

            }

            resource "aws_subnet" "pub2"{
                
                vpc_id = aws_vpc.main.id 

            }


The graph produced by Terraform would be two AWS subnet objects, both pointing at the AWS VPC, meaning that each subnet references the VPC, which we can see in the subnet code block. 
The VPC ID is referenced in both. What makes this relationship a dependency is the fact that the VPC ID is unknown until the VPC is created, so Terraform can't create the subnets until it knows that ID. 
The dependencies create an order of operations. Terraform knows it has to create the VPC first and then the subnets. It can create both subnets in parallel since they have no dependencies on each other. 

Terraform includes a terraform graph command that will generate a diagraph document based on your current configuration. The command is simply terraform graph. 
Run by itself, it will show you the relationships of all the resources and data sources in your configuration. 

You can get a more detailed graph that includes variables, providers, and outputs by specifying the type argument and setting it to plan, plan‑refresh‑only, plan‑destroy or apply. 
 
    $ terraform graph  ===> Create graph of resources
 
    $ terraform graph -type=[plan, plan‑refresh‑only, plan‑destroy or apply]      ===> more detailed graph of resources using one of teh options

The resulting graph is more detailed, but it's also harder to read. 
You can also pass the graph command a saved execution plan, and it will draw the graph based on the contents of the plan. 
Let's see it in action. Over in VS Code, I'm going to run terraform graph against our taco_wagon configuration. 

# Configure Explicit Dependencies
Now that we've got a solid idea of how Terraform determines dependencies and actions to perform, how do we influence those decisions? 
There are two arguments you need to know about, depends_on and the lifecycle block. We'll cover the lifecycle block in a future module. 

The depends_on argument works with all resource types, modules, and outputs. 
The argument goes inside of the block where you want to declare a dependency, and it takes a list of references to other objects that this object is dependent on. 
When Terraform generates an execution plan, it will ensure that all actions on the dependent objects are complete before acting on the current object. 

If you declare a module as a dependency, that includes all resources and outputs in that module. Caution when it comes to the depends_on argument. 
As we've already seen, Terraform determines dependencies through references, and usually it's better to use references than an explicit depends_on argument. 
References are more exacting and give Terraform a better understanding of how your resources are related. 

However, there may be times where you need to express a dependency, even though there's no direct reference. 
In fact, we've got that problem right now. One of the configuration challenges with the Taco Wagon team was to ensure the logging bucket is created before the EC2 instance. 

Let's take care of that now. Heading back to the Taco Wagon code, I'll open up the maint.tf and scroll down to our EC2 instance. There it is. I'll add the depends_on argument to the bottom of the block, since that's where I typically put it, but it doesn't really matter. For the value, I will add a list containing the aws_s3_bucket.logging. Now Terraform should create the bucket before the AWS instance. We can confirm by pulling up the terminal and running the terraform graph again. Once the diagraph pops up, I'll copy it over to our browser and see how things look. Pasting in the updated diagraph, we get our more simplified diagram this time. And now there's a dependency between the AWS instance and the logging bucket. That's what we were looking for. Heading back to the terminal, I'm going to deploy the configuration and validate the order of operations. I'll run a terraform apply and wait for the plan to come up. The plan doesn't show the order of operations, but we can track it during the apply. I'll approve the apply, and now let's see the order in which it creates the resources. It should start with the VPC and S3 buckets, which it does. I'll jump ahead to when the deployment completes. All right, the deployment is complete. I'll copy the URL from the output and paste it into a browser. After a few minutes, the page should load, and there we go. The Taco Wagon deployment is live. We have successfully configured an explicit dependency with the depends_on argument. 

    $ cd /home/cogx/my-stuff/terraform/intermediate/08-lifecycle-management [move to module directory]

    $ cd 01-graph-dependencies/  [module to lesson directory]

    $ cp -R ../base_apps/taco_wagon .  [copy application to work on using above requirements]

    $ cd taco_wagon/

    $ terraform init    [initialize the  project]

    $ terraform graph   [ shows the dependency graph]

        digraph G {
            rankdir = "RL";
            node [shape = rect, fontname = "sans-serif"];
            "data.aws_availability_zones.available" [label="data.aws_availability_zones.available"];
            "data.aws_ssm_parameter.amzn2_linux" [label="data.aws_ssm_parameter.amzn2_linux"];
            "aws_instance.web" [label="aws_instance.web"];
            "aws_internet_gateway.main" [label="aws_internet_gateway.main"];
            "aws_route_table.public" [label="aws_route_table.public"];
            "aws_route_table_association.public" [label="aws_route_table_association.public"];
            "aws_s3_bucket.cache" [label="aws_s3_bucket.cache"];
            "aws_s3_bucket.logging" [label="aws_s3_bucket.logging"];
            "aws_security_group.main" [label="aws_security_group.main"];
            "aws_subnet.public" [label="aws_subnet.public"];
            "aws_vpc.main" [label="aws_vpc.main"];
            "aws_vpc_security_group_egress_rule.all_outbound" [label="aws_vpc_security_group_egress_rule.all_outbound"];
            "aws_vpc_security_group_ingress_rule.http_access" [label="aws_vpc_security_group_ingress_rule.http_access"];
            "aws_instance.web" -> "data.aws_ssm_parameter.amzn2_linux";
            "aws_instance.web" -> "aws_security_group.main";
            "aws_instance.web" -> "aws_subnet.public";
            "aws_internet_gateway.main" -> "aws_vpc.main";
            "aws_route_table.public" -> "aws_internet_gateway.main";
            "aws_route_table_association.public" -> "aws_route_table.public";
            "aws_route_table_association.public" -> "aws_subnet.public";
            "aws_security_group.main" -> "aws_vpc.main";
            "aws_subnet.public" -> "data.aws_availability_zones.available";
            "aws_subnet.public" -> "aws_vpc.main";
            "aws_vpc_security_group_egress_rule.all_outbound" -> "aws_security_group.main";
            "aws_vpc_security_group_ingress_rule.http_access" -> "aws_security_group.main";
        } 


Go to GraphvizOnline in the browser and paste the above output in the editor on the LHS.
You can see the visualization on the RHS        


    $ terraform graph -type=plan  [paste output in GraphvizOnline to see dependency graph of variables, providers, locals, and outputs]


# Practicals Globomantics Scenario
This time around, you are a platform engineer and Terraform expert who's been tasked to help out the application teams with their infrastructure woes. 
We've got three teams that need help, Taco Wagon, Burrito Barn, and Sopes Saloon. 

In our first scenario, the Taco Wagon team has deployed their application configuration, but they're running into some issues.

    1. The S3 logging bucket should be created before the EC2 instance so no logs are missed and protected against deletion
    2. The security group needs to be renamed
    3. The S3 asset cache should be recreated when the application version is updated. 
    4. Finally, the tags on the EC2 instance are being managed by a tag policy at the organization level, 
      and Terraform keeps reverting the changes. We can solve all of these issues through Terraform.    

# Solution 1   

     $ cd taco_wagon/  [make sure to be in this directory]

In main.tf, scroll to the aws_instance.web and add the depends_on dependency on aws_s3_bucket.logging

        depends_on = [ aws_s3_bucket.logging ]

    $ terraform init    [initialize the  project if not done already]

    $ terraform graph  [paste output in GraphvizOnline to see dependency of aws_instance.web on aws_s3_bucket.logging ]

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out m1.tfplan

    $ terraform apply m1.tfplan

    $ terraform destroy [deletes all resource if you are not continuing with  next module immediately]
    
Continue to other module to see the other solutions