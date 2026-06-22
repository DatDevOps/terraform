<!-- Data Sharing Alternatives -->
# NOTE :I'll preface this by saying that the tfe_outputs data source requires that the source configuration is using either HCP Terraform or Terraform Enterprise as its state back end. 
# Otherwise, this won't work. While we won't be implementing the tfe_outputs data source in this course if you'd like to take it for a spin yourself, I've included a folder and instructions in the solution's m3 directory.


Sharing data across configurations is critical to building out complex infrastructure deployments. 
And we've seen that the terraform_remote_state data source can get the job done. But it's not all sunshine and rainbows. 
There are some distinct challenges and drawbacks to using remote state as a data source. So let's discuss its issues and some possible alternatives. 

I want to start by saying that it's not just me that recognizes the drawbacks of using terraform_remote_state. 
In fact, if you look at the official documentation for the data source, right at the top of the page, HashiCorp recommends against using it. 
Not only that, but it makes some alternative recommendations about how to share information. 
Before we get into those recommendations, let's talk about the issues with terraform_remote_state so you can make an informed decision. 

The way I see it, there are two primary drawbacks to using terraform_remote_state as a means of passing configuration information. 
The first is a security concern. In order for the calling configuration to use the terraform_remote_state data source, it needs to have full read access to the source configuration's state data. 
The data source itself is restricted to only the outputs, but the credentials used to run the configuration will have read access to the entirety of state data, including all resources and data sources. 
That could potentially expose sensitive information to someone who shouldn't have access. 

Consider a simple situation where the source configuration uses a data source to load the contents of an AWS Secrets Manager secret. 
That secret value is now stored in state data. The credentials from the calling configuration would have access to that secret value, even though it isn't exposed as an output. 
Maybe that's a problem, maybe it's not, but it's certainly worth considering. 

Additionally, the terraform_remote_state data source doesn't take into account the sensitivity marker for outputs from the source configuration. 
Now the sensitive marker really only obscures the value from terminal output, but again, this is a potential security concern that you should be aware of.

The second major drawback is about the tight coupling the remote state data source creates between the source configuration and the calling configuration. 
When you use the terraform_remote_state data source, you are creating a dependency between the two configurations that the maintainer of the source configuration must take into account. 
If anything changes about the source configuration's state or outputs, that could potentially break the linkage between the two. 

What could change? The source configuration might migrate to a different state back end, breaking the data source config. 
The source configuration might change the name of an output or the data type returned by that output. This would break the data source references in the calling config. 
Or the maintainers of the source configuration might want to migrate some resources to a different config, again, breaking the linkage between the two configurations. 
This is further compounded in situations where the source configuration is referenced by multiple downstream configurations, such as a shared network configuration leveraged by multiple applications. 
One change to the network configuration could become a breaking change for all applications that rely on it. 
I'm not saying you should never use the terraform_remote_state data source, but I think it's important to approach it, knowing the potential risks and weighing them against the benefits.

# The tfe_outputs Data Source
Let's say you've reviewed the potential risks of using the terraform_remote_state data source and you found them unacceptable. What are your alternative options? Good news, there's a lot. 
For starters, if you're fine with the tight coupling of configurations and your main concern is around the security of sharing state data, there is a solid alternative, the tfe_outputs data source. 

Now I'll preface this by saying that the tfe_outputs data source requires that the source configuration is using either HCP Terraform or Terraform Enterprise as its state back end. 
Otherwise, this won't work. Assuming you're using HCP Terraform or Terraform Enterprise, then you can swap out the terraform_remote_state data source with the tfe_outputs data source. 
It brings two important enhancements with it. 

First off, rather than granting the calling configuration read access to the entirety of state data, you can instead grant it only access to the output values. 
The tfe_outputs data source does not require read access to state data and uses the API to query just the outputs. 

The second improvement is that tfe_outputs recognizes the sensitivity marker on outputs and lets you reference only non‑sensitive outputs or all outputs. Let's check out the syntax for the data source. 

The data source type is tfe_outputs. Inside the block, you need to specify how to connect to the workspace in HCP Terraform or Terraform Enterprise that houses the source configuration. 

#syntax 

    data "tfe_outputs" "networking" {
        organization = "my-tfe-org"
        workspace    = "taco_wagon_net"
    }

#references

    data.tfe_outputs.networking.values["vpc_id"]

    data.tfe_outputs.networking.nonsensitive_values["vpc_id"]

You'll need to provide the organization name and the workspace name as arguments. And that's it. There's no other arguments supported by the data source. 
To reference an output from the data source, there are two available attributes. Take a look at the above example. 

Here we have a tfe_outputs data source named networking that's tied to the workspace taco‑wagon‑net. 
The first attribute is the values attribute, and this will return all outputs defined in the source configuration. But it will preemptively mark all of those outputs as sensitive. 

Any outputs you reference from the values attribute will have their sensitive marker set to true. 
The other attribute is the nonsensitive_values attribute, and it contains exactly what it sounds like, only the outputs whose sensitive marker is set to false. 
Unless you know you need access to sensitive outputs, this is probably the attribute you'll use. 
While we won't be implementing the tfe_outputs data source in this course, if you'd like to take it for a spin yourself, I've included a folder and instructions in the solution's m3 directory.

# Remote State Data Source Alternatives
The tfe_outputs data source may solve for your security concerns, but it doesn't really get around the tight coupling of state data. 
Fortunately, there are a host of other services you can use to store configuration data and data sources to support them. 
What kind of services can you leverage? If you're looking to store general key value data, each cloud platform has options for you. 
AWS has SSM Parameter Store, Azure has App Config or Table storage, and Google Cloud has Cloud Datastore. 

If you don't want to use a particular cloud platform, you can always opt for something like Redis, HashiCorp Consul or Kubernetes ConfigMaps. 
You can also leverage DNS services to record hostnames and IP addresses. 

And if you need to share sensitive information, you can use the secrets management solutions on each cloud platform, like Azure Key Vault and AWS Secrets Manager, or a third‑party solution like HashiCorp Vault. 
Selecting one of these solutions removes the tight coupling of terraform_remote_state. 
The source configuration can write its information to any viable target service, and the calling configuration can access that information using the correct data source for that service. 
By using a commodity solution instead of Terraform state directly, the way in which the information is populated is no longer relevant to the calling configuration. 

As long as the information is stored in the correct place, the team managing the source infrastructure can alter things as they see fit. 
They can change outputs, move resources to other configurations or migrate to another tool instead of Terraform. 
As long as the correct information is still published in the right place, how it gets there doesn't matter to any of the configurations consuming it. 
You also get fine‑grained control over what information is published, how it's presented, and what level of access the calling configuration has to the information, solving both the tight coupling and security concerns. 

The downside is that you now have to manage, maintain, and secure another service to hold your configuration data. 
Chances are you're already using such services for other things in your organization, but it is a consideration to take into account.

# Special Data Sources
The standard key value stores, DNS services, and secret storage solutions all have providers and data sources that can be used to query for information. 
There's the AWS, Azure, and Google Cloud providers for any of their platform services, and there's also a generic DNS provider for interfacing with DNS services and retrieving record sets. 
And there's providers for Redis, Consul, Vault and more. But what if you encounter a situation where there isn't a provider for the solution you want to use? 

Well, there are a few special providers and data sources that may come in handy. 

    -   The local provider includes a local file and local sensitive file data source. If you're passing your configuration data through a file, you can leverage either of these data sources. 

    -   The HTTP provider includes only the HTTP data source, which can be used to make generic HTTP requests to the endpoint of your choosing. 
        If you're storing your data somewhere with an HTTP API front end, you could craft an HTTP request to retrieve your data using this data source. 

    -   Another specialty data source that is even more flexible is the external data source. 
        This data source takes a program to run as an argument and makes the resulting response of the program available. 
        The program or script will receive its data through stdin in JSON format, and it must return a JSON object through stdout with an exit code of 0. 
        This means you can write whatever script or program you want and have Terraform execute it through the external data source. 
        This does create a dependency on the program or script, so it's not as robust or self‑contained as the other data sources we've discussed. 
        But if you're truly struggling to find a way to access data outside of Terraform, the external data source can be a last resort.

# Practical Migrating the Network Data
The Taco Wagon team has been discussing things with the networking team. 
They would like to store the network information in the AWS SSM Parameter Store instead of using the remote state data source. 
The networking team is worried about exposing potentially sensitive information, and the Taco Wagon team doesn't love the tight coupling that Terraform state creates. 
To support this change, we will need to update the network configuration to write data out to the SSM Parameter Store. 
We'll also need the name of the Parameter Store entry to share with the Taco Wagon team. 

On the application side, we need to update the configuration to include an input variable with the SSM parameter name 
and then add a data source for that parameter and use it for the network information. Let's get started.

- Create S3 backend for taco_wagon_app and taco_wagon_net

    $ cd ./03-external-data-sources/tfstate-backend

    $ terraform init

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform plan -out s3-backend.tfplan

    $ terraform apply s3-backend.tfplan

        ...
        ...
        Outputs:

        app_bucket_config = {
            "bucket" = "tacowagon-app20260616134741912700000002"
            "region" = "us-east-1"
        }
        net_bucket_config = {
            "bucket" = "tacowagon-net20260616134741912600000001"
            "region" = "us-east-1"
        }


Use the respective values to setup the backend for taco_wagon_net and taco_wagon_app


- For taco_wagon_net

#add this to main.tf

    resource "aws_ssm_parameter" "vpc_id" {
        name           = "/taco-wagon-networking/${var.environment}/vpc-id"
        description    = "VPC ID for the Taco Wagon app"
        type           = "String"
        insecure_value = aws_vpc.main.id

        tags = {
            environment = "development"
            application = "taco-wagon"
        }
    }

    resource "aws_ssm_parameter" "public_subnets_ids" {
        name           = "/taco-wagon-networking/${var.environment}/public-subnet-ids"
        description    = "Public Subnet IDs for the Taco Wagon app"
        type           = "StringList"
        insecure_value = join(",", aws_subnet.public[*].id)

        tags = {
            environment = var.environment
            application = "taco-wagon"
        }
    }

#outputs.tf

    Remove all outputs since they are now stored in ssm parameter store

First deploy the vpc and related resources

    $ cd ./03-external-data-sources/taco_wagon_net

    $ terraform init -reconfigure [ -reconfigure flag bcs the backend s3 bucket was changed]

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform apply


- For taco_wagon_app

    checkout variable.tf, terraform.tfvars, and main.tf files to see the commented out code and the replace using ssm parameter store values

Now deploy the appc and related resources

    $ cd ./03-external-data-sources/taco_wagon_app

    $ terraform init -reconfigure [ -reconfigure flag bcs the backend s3 bucket was changed]

    $ terraform fmt --recursive

    $ terraform validate

    $ terraform apply

    ...
    ...
    Outputs:

    application_url = "http://54.242.133.223"
    web_instance_id = "i-0104c1648d3c90ed1"
    web_instance_public_ip = "54.242.133.223"

# Cross-configuration Dependency Updates
There's one more thing I want to mention about managing multiple configurations. 
When the entire infrastructure exists in the same configuration, any changes in one resource or group of resources has an immediate impact on the dependent resources. 
Terraform creates the resource graph, and all the dependencies are mapped out. So if you replace the public subnets, that will force a recreation of the EC2 instances using those subnets. 
Once you separate the terralith into multiple configurations, the graph of each configuration is unaware of dependent resources in other configurations, and that can lead to a few different challenges. 

For starters, you may not be able to recreate certain resources that are used by dependent configurations. 
In my previous example, AWS won't let you destroy a subnet that has network interfaces attached, so the attempted operation would fail. 
That's a best‑case scenario since it wouldn't result in a disruption of services. 

Not all resources have that level of protection, so another scenario could result in disconnection or deletion of dependent resources. 
Terraform doesn't have a global view of your infrastructure to understand cross‑configuration dependencies. 

A third scenario would be the removal or renaming of a resource that would require an update on a dependent resource in another configuration. 
Imagine renaming an S3 bucket in one config and breaking the logging or static asset caching in another config. 
Fixing it would only require a fresh plan and apply on the dependent configuration, but how would it even know something had changed? 
It's up to you and your team to maintain and put in proper change controls to avoid unintended outages. 

On that subject, I have a few pieces of advice. Before splitting up a configuration, consider the dependencies in the configuration. 
-   You should try minimizing splitting dependencies across configurations whenever possible. 
-   When not possible, make sure the dependency is documented in the README for both configurations and that you have set up some type of alerting in case things change unexpectedly. 
-   In your automation pipelines, set up a trigger to kick off runs into pending configurations when the source configuration has a successful apply. 
-   And lastly, you should check out solutions like HCP Terraform Stacks, Terragrunt or Terramate that all incorporate the idea of cross‑configuration dependencies into their solution. 

By putting these practices and operations into place, you can safely break up your configurations while still maintaining linkage between them.