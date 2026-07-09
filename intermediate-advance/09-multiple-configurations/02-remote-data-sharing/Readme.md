<!-- Passing Data across Configurations -->

Data sources are a great way to query a platform for information dynamically, but they're also a way to tie multiple configurations together. 
Let's consider how a configuration passes information internally. 

When you're building out your Terraform configuration, you can pass around information in the root module using direct object references. 
If I'm creating an AWS security group with the name label web and I want to assign it to an EC2 instance in the same module, I can use the reference aws_security_group.web and the attribute id. 

    aws_security_group.web.id

What about communication between the root module and child modules? As you may already remember from the module's course or your own experience, 
you can pass information into a child module using input variables and reference attributes of the module using outputs. 

Let's say I'm using a module to create my VPC and I need to pass the public subnet IDs from the module to the web front‑end module that provisions a load balancer. 
My VPC module would have an output named public_subnets, and my web front‑end module would have an input variable called subnets. 
If my VPC module is named web_net, I can reference the public subnet's output using the syntax:

    module.web_net.public_subnets. 

And that would go in my web front‑end module block as the value for the subnet's arguments. 
Passing information around your root modules and child modules is pretty straightforward, since you can leverage references and all the information is stored in the same instance of state data. 

But what if you want to reference something in another configuration? As your infrastructure grows in complexity and scale, it becomes untenable to manage it all in a single configuration. 
You may choose to split your configurations up based on teams, roles and responsibilities or blast radius. 

Let's start with an example infrastructure that's deployed in AWS. Here we have a basic two‑tier application. 
It's composed of a network layer that includes a VPC, subnets, internet gateway, and route tables. 
On top of that, we have an RDS instance and its accompanying components that form the database layer. 
For the web front end, there's an auto‑scale group, load balancer, security groups, and possibly more. 

And beyond all these obvious components, there could be IAM policies, roles, and even AWS config components. 

You can deploy this whole thing as a single monolithic configuration, a terralith, if you will. But that probably doesn't make sense. 

The VPC might be used for other applications, you might have a security team that manages IAM roles and policies for the entire account, and maybe you have a database team that manages all RDS instances. 
Rather than letting all these teams try and work on the same Terraform configuration, we can break things up. 
There can be a networking config managed by the network team, an IAM config managed by the security team, a database config managed by the DBAs, and finally, the web tier config managed by the application team. 

This arrangement becomes increasingly necessary as you scale to multiple environments where you might have a dev, QA, staging, and production instance all being managed. 
Separating your configuration makes sense from an operational and administrative standpoint, but it does introduce a new challenge. 
Whereas before you could link all of these components together using direct references, now you need another mechanism to pass information, and that's where data sources come into the picture.

<!-- Terraform Remote State Data Source -->

One of the options to share data across configurations is to leverage functionality that is similar to passing information across modules, namely, outputs. 
The terraform_remote_state data source allows one configuration to query the state data of another config, like passing data from a child module to its parent. 
The terraform_remote_state data source can only reference root module outputs that are defined in the source configuration. 
So if you want to pass information, it must be set as an output first and applied so the output is populated inside of the state data. 

Consider the example environment we were looking at before. We split our terralith into four separate configurations, but we still need to pass data between them. 
Each configuration will have its own instance of state data, and we can define outputs in each configuration for the other configurations to consume. 

For instance, we can define outputs for the vpc_id and subnet_ids so our RDS configuration and web front‑end configuration can query for them. 
And the database configuration can define connection info for the web front end to query. 
The web front‑end configuration may also pull from the IAM configuration for proper IAM policies and roles. 

Let's see what the syntax looks like for the terraform_remote_state data source and how to reference the outputs. 
The terraform_remote_state data source starts with the data keyword, and the type is terraform_remote_state. 
The provider for the data source is the built‑in Terraform provider. That's part of the core binary, so there's no provider block to define or plug‑in to download. 

Inside the block, you have to specify the backend type for the source configuration using the backend argument. Any back‑end type is supported as long as the calling configuration can access it. 
The config argument defines how to connect to the selected back‑end type. The value is a map, and the keys in the map will depend on the back‑end type. There are two other available arguments. 

The first is workspace. If you're using the community version of workspaces, you can specify which workspace to pull state data from. 
If you don't include this argument, the data source will pull from the default workspace. 
The other argument is defaults. This argument lets you define default values for the outputs if the reference state data is empty or the output is missing. 

Let's check out what that syntax looks like. 

#syntax
 
    data "terraform_remote_state" "<named_label>"{
        backend = "<backed_type>"

        config = {
            #Backend specific config
        }

        workspace = "<workspace_name>"
        defaults = {} #object of defaults values

    }


For example, let's say I have a networking configuration that uses S3 for its state back end, and I want to pull information from it for my application config. 
The terraform_remote_state data source is called network, and inside the block, I have the backend argument set to s3 and the config argument set to the required values for the S3 back end, including region, bucket, and key. 

    data "terraform_remote_state" "network"{
        backend = "s3"

        config = {
            #Backend specific config
            region = "us-east-1"
            bucket = "taco-wagon-net"
            key = "terraform.tfstate"
        }
    }

The syntax for referencing an output is:

    data.terraform_remote_state.<name_label>.outputs [the output name you want to reference. ]

So if I have an output called public_subnet_ids I want to use in my application config, the argument value would be 

    data.terraform_remote_state.network.outputs.public_subnet_ids

There are a couple of things you need to know about the terraform_remote_state data source. 

First of all, the data source doesn't pass through the sensitive label for an output. 
So if you have an output set as sensitive in the source configuration, it will not be marked as sensitive in the target configuration. 

The second thing is regarding security. Although you can only reference outputs using the data source, 
the process or user running the target configuration needs to have read access to the entirety of state data. 
Any sensitive information stored in state, even if it isn't defined as an output, would be accessible to that user or process. 
It's not necessarily a huge issue, but it is something to be aware of.

# Practicals
Split the taco-wagon configuration into two
    - Networking
    - Application
    - Moved the remote backend
    - Move away from passing values between the two congurations using variables to using terraform_remote_state

# Solution

- Create S3 backend for taco_wagon_app and taco_wagon_net

    $ cd ./02-remote-data-sharing/tfstate-backend

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out s3-backend.tfplan

    $ terraform apply s3-backend.tfplan

        ...
        ...
        Outputs:

        app_bucket_config = {
            "bucket" = "tacowagon-app20260616003241917300000001"
            "region" = "us-east-1"
        }
        net_bucket_config = {
            "bucket" = "tacowagon-net20260616003241922400000002"
            "region" = "us-east-1"
        }


- Deploy taco_wagon_app and taco_wagon_net as is without using terraform_remote_state to pass values between them

First the vpc and related resources

    $ cd ./02-remote-data-sharing/before-adding-data-remote/taco_wagon_net

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform apply
        ...
        ...
        Outputs:

        vpc_id = "vpc-0df6f054d686846db"    

secondly, go to the console and copy the subnet ids for the vpc just deployed and enter it in terraform.tfvars of taco_wagon_app file as below

        public_subnet_ids  = ["subnet-0d420c42c01863600", "subnet-09d7ace2af98612af"]

        vpc_id = "vpc-0df6f054d686846db"

Now deploy taco_wagon_app        

    $ cd ./02-remote-data-sharing/before-adding-data-remote/taco_wagon_app

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform apply [correct any error or proceeed if successful]

        Outputs:

        application_url = "http://54.234.40.27"
        web_instance_id = "i-0ae613908183b0ccc"
        web_instance_public_ip = "54.234.40.27"

If the taco_wagon_net and taco_wagon_app deployed successfully, it shows our configuration is working even if we have to pass values manually from one config to another.

Now destroy the taco_wagon_net and taco_wagon_app but not the s3 backet as we will use it in our 02-remote-data-sharing/after-adding-data-remote

    $ terraform destroy [run the command in each of taco_wagon_net and taco_wagon_app to delete resources]

Let us now dynamically get the vpcid and subnets ids from the state of taco_wagon_net instead of had coding it


First the vpc and related resources. Notice the new output definition in outputs.tf and terraform.tf in taco_wagon_net

- terrafom.tf

        backend "s3" {
            bucket       = "tacowagon-app20260616003241917300000001"
            region       = "us-east-1"
            key          = "taco-wagon-app.tfstate"
            use_lockfile = true
            profile      = "my-sandbox"
        }

-  outputs.tf  

        output "public_subnet_ids" {
            description = "List of public subnet IDs."
            value       = aws_subnet.public[*].id
        }

Lets now run the below to deploy the taco_wagon_app

    $ cd ./02-remote-data-sharing/after-adding-data-remote/taco_wagon_net

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform apply -auto-approve=true

        ...
        ...
        Outputs:

        public_subnet_ids = [
        "subnet-05209e438c5067561",
        "subnet-0b7d48d01dab8805c",
        ]

        vpc_id = "vpc-0ba962517d5870d4e"


Now deploy taco_wagon_app. Note this additions

- variable.tf

        variable "network_bucket_config" {
            description = "Config for the network state bucket"
            type = object({
                bucket = string
                region = string
                key    = string
                profile = string
            })
        }

- terraform.tfvars

        network_bucket_config = {
            bucket = "tacowagon-net20260616003241922400000002"
            region = "us-east-1"
            key    = "taco-wagon-net.tfstate"
            profile = "my-sandbox"
        }

- terrafom.tf

        backend "s3" {
            bucket       = "tacowagon-app20260616003241917300000001"
            region       = "us-east-1"
            key          = "taco-wagon-app.tfstate"
            use_lockfile = true
            profile      = "my-sandbox"
        }

- main.tf

        resource "aws_security_group" "web" {
            ...
            ...
            vpc_id      = data.terraform_remote_state.net.outputs.vpc_id
            ...
            ...
        }

        data "terraform_remote_state" "net" {
        backend = "s3"

        config = var.network_bucket_config
        }

        resource "aws_instance" "web" {
            ...
            ...
            subnet_id = data.terraform_remote_state.net.outputs.public_subnet_ids[0]
            ...
            ...
        }        


Run the commands to deploy the taco_wagon_app configuration

    $ cd ./02-remote-data-sharing/before-adding-data-remote/taco_wagon_app

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate        

    $ terraform apply -auto-approve=true
        ...
        ...
        Outputs:

        application_url = "http://3.84.20.248"
        web_instance_id = "i-0c596cb29a9cf4cc9"    

# Remote State Considerations
In most environments, you won't use the same state back‑end location for all of your configurations. 
    -   Your network configuration will probably use one S3 bucket and your DB config another, your app config another, etc. 
    -   Likewise, you probably won't be using the same credentials for the deployment of all these configurations. 
    -   Provide the calling configuration permissions to read the source configuration's state data and nothing more to access state data. 
    -   Source state data must be reachable by the calling process

However, since all of state data is stored as a single object or file, you cannot restrict the calling configuration's access to only the outputs of the state. 
The calling configuration also needs to be able to access the state data from where it's running. 
When you're using something like S3, that should be relatively simple, but if the network team locked down their S3 bucket to only allow connections from certain IP addresses or 
decided to use PrivateLink to restrict access to certain VPCs, then you need to make sure that wherever your app configuration deploys from, it still has connectivity to the networking state bucket. 

