<!-- Sensitive Data -->

Both variables and output configuration blocks support the use of a sensitive argument. 
The argument is a Boolean value that defaults to false. When set to true, the value of the 
variable or output will be redacted from the console output and the plan and apply logs. 

The sensitive flag follows the value as it's used throughout the configuration, unless you remove it with the non‑sensitive function. 
You can also dynamically mark values as sensitive using the sensitive function. 

What the sensitive flag doesn't do is encrypt or secure the contents of the variable or output. 
It just prevents it from being displayed in plain text, in normal workflows, or included in the standard logs. 
It's still possible to get the value printed to the terminal if you're deliberate about it

Consider these two blocks where we have an output that's marked as sensitive. 

#main.tf

    #defines a variable to hold the value of an api key
    variable "api_key" {
        type = string
        description = "API Key application"
        sensitive = true
    }

    #outputs the value of the key above
    output "ssh_key {
        description = "ssh key for connections"
        sensitive = true
    }

If I simply run 'terraform output', it will show me the output name, but the value will be redacted and marked as sensitive. 
If we took a look at the state for this configuration, the actual value for the output is still stored in plain text and state. 
And if we change our output command to include the output name - 'terraform output ssh_key', the actual value will be printed to the terminal. 
The sensitive argument is still useful, but you need to be mindful of its limitations. 
It does redact the value at the terminal and in logs, but it does not secure or encrypt the actual value. 

If you must have sensitive data in your state, and generally it is unavoidable, you should take steps to secure your state data. 
First, you should use a remote state back end that supports both encryption at rest and in transit - including S3, Azure Storage, and HCP Terraform. 

Second, you should apply access controls to your state data to prevent unauthorized access - IAM with S3, Azure RBAC with Azure Storage, and HCP Terraform has built‑in access controls. 

Ultimately, the best place to store sensitive data is outside of Terraform entirely, but that's not always an option. 

Another potential location for sensitive data is in your saved plan file. The actual file that gets saved is in a binary format that you can't read directly. 
Using terraform show will give you a consistent readable view of the contents, and you can get them in JSON format if you'd like. 
The terraform show command still obscures some things that are stored in the plan, but the file itself is really just a ZIP archive of your configuration, current state, plan changes, and previous state. 
There's a lot of potentially sensitive information sitting in your plan file. All the same protections you apply to state should also be applied to saved plan files. 
You should store them encrypted, control access to them, and additionally, delete them as soon as the plan has been successfully applied. 
The one thing that's not stored in your plan are provider credentials. Those need to be provided with each terraform plan and apply. 
Everything else is in there though, so be careful with your plan files.

# Ephemeral values and resources
Ephemeral values remove sensitive information from state data and saved plans, but still make use of it in your configurations

#Ephemeral values

    #defines an ephemeral variable to hold the value of an api key
    variable "api_key" {
        type = string
        description = "API Key application"
        ephemeral = true
    }

    #outputs the ephemeral value of the key above
    output "ssh_key {
        description = "ssh key for connections"
        ephemeral = true
    }

#Ephemeral resources

    ephemeral "aws_ssm_parameter" "ssh_key" {
        name = var.ssh_key
    }

#ephemeral resource reference

    resource "aws_instance" "web"{
     #...
     connection{
        type  = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = ephemeral.aws_ssm_parameter.ssh_key.value
     }

    }

To avoid an ephemeral value being written to state or a plan file, it cannot be used as a value for an argument that is written to state or recorded in a plan, 
which really limits where you can use them. Because root module outputs are written to state, they cannot be marked as ephemeral, only child module outputs. 
Most data sources and resource arguments are also written to state, so you cannot use an ephemeral value there either. So, where can you use ephemeral values? 
Well, there are a few use cases. The provider credential is not recorded in state or plan, so you can use an ephemeral value to pass sensitive credentials to the provider. 
Likewise, the credentials used to run a remote provisioner are also not stored in state or plan, so you can use an ephemeral value to pass credentials to the remote exec and file provisioners. 
Lastly, some resources have been updated to support write‑only arguments. 
These are arguments that are specifically designed to not be stored in state or a plan file, and so they're compatible with ephemeral values   

Well, there are a few use cases. The provider credential is not recorded in state or plan, so you can use an ephemeral value to pass sensitive credentials to the provider. 
Likewise, the credentials used to run a remote provisioner are also not stored in state or plan, so you can use an ephemeral value to pass credentials to the remote exec and file provisioners. 
Lastly, some resources have been updated to support write‑only arguments. These are arguments that are specifically designed to not be stored in state or a plan file, and so they're compatible with ephemeral values. Let's take a look at an example. I have an input variable called API key that's been marked as ephemeral. We wouldn't be able to use this with a normal argument, but we can use it with a write‑only argument. 
The aws_ssm_parameter store has been updated to include a write‑only argument, which is called value_wo for write‑only and is used in place of the value argument. When you use value_wo, the value is not recorded in state or plan. 


    #defines an ephemeral variable to hold the value of an api key
    variable "api_key" {
        type = string
        description = "API Key application"
        ephemeral = true
    }

    #resource
    ephemeral "aws_ssm_parameter" "api_key" {
        name = "taco-wagon/api-key"
        type ="SecureString"
        value_wo = var.api_key
    }

The fact that the value for an argument is not recorded in state makes it pretty difficult for Terraform to know if the value has changed.
Terraform compares what's in state to your configuration to determine if changes have been made. With write‑only arguments, there's nothing to compare the new value to. 
The general solution for this is to add a second argument to signal to Terraform that the write‑only argument should be updated. In the case of the ssm_parameter_resource, the second argument is value_wo_version, which is recorded in state. When you want to update the write‑only argument, you pass a new value for both the value_wo and value_wo_version arguments, and Terraform will plan to update both. 


    #defines an ephemeral variable to hold the value of an api key
    variable "api_key" {
        type = string
        description = "API Key application"
        ephemeral = true
    }

    #resource
    ephemeral "aws_ssm_parameter" "api_key" {
        name = "taco-wagon/api-key"
        type ="SecureString"
        value_wo = var.api_key #pass a new value to update ephemeral resource
        value_wo_version = var.api_key #pass a new value to update ephemeral resource
    }

One important thing to note about ephemeral resources and values is that they may change between plan and apply because they are evaluated independently during each run. It's not a huge deal, but it does mean that the resulting infrastructure may be slightly different than what was saved in the plan file depending on how you use it. I guess that's the price we pay for better data security.

# Practicals
- Generate an application password
- Stores the password in AWS Secret Manager
- Update using input variable

Before begining the practicals, do:

    $ cd 05-hcl-expressions/06-sensitive-data

    $ cp -R 05-hcl-expressions/05-splat-for-expressions/base_app .

    $ rm -rf m5.tfplan 

# Solution

1. Add this to main.tf. it contains secret manager resource and a random provider generated secret

    #module exercise requirements
    ephemeral "random_password" "app_password" {
        length  = 16
        special = true
    }

    resource "aws_secretsmanager_secret" "app_password" {
        name_prefix = format("%s-app-password-", local.name_prefix)
        tags = local.common_tags
    }

    resource "aws_secretsmanager_secret_version" "app_password_version" {
        secret_id                = aws_secretsmanager_secret.app_password.id
        secret_string_wo         = ephemeral.random_password.app_password.result
        secret_string_wo_version = var.app_password_version
    }

2. A new variable definition in variable.tf to hold the secret version. increment this value to general a new password when desired

    #module exercise requirements
    variable "app_password_version" {
        description = "Version number for the generated app password"
        type        = number
    }

3. Assign a default value to  app_password_version in terraform.tfvars

    app_password_version = 0

Once you are done, run the below:

    $ terraform init [initialization needed again even if you have done it b4 because of the new random provider]

    $ terraform fmt

    $ terraform validate

Note the ephemeral.random_password resource is opened, and then the password version is created, and then the ephemeral resource is closed. 
Terraform only accesses an ephemeral resource when it's actively needed, and then flushes it from memory. 

    $ terraform plan -out m6.tfplan

        ephemeral.random_password.app_password: Opening...
        ephemeral.random_password.app_password: Opening complete after 0s
        ...
        ...
        ephemeral.random_password.app_password: Closing...
        ephemeral.random_password.app_password: Closing complete after 0s
        ...
        ...

    $ terraform apply m6.tfplan

Search for secret_string_wo in terraform.tfstate and jump down to the actual resource that's been created. 
The value stored for secret_string_wo is null, meaning that our password isn't captured in state 

Note that Changing the secret_string_wo_version also changed the secret that was stored in AWS Secrets Manager.