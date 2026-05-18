<!-- Terraform  workflow -->

# Terraform init: Looks at your configuration files, main.tf and teeraform.tf, at the root of directory to find out what Terraform configuration to use. It finds the required provider and download it if it has not be downloaded. It also get a state backend ready. If you did not provide one, it creates a state data file in the  current working  directory. You only need to run init again when your state backend, provider, or modules chnages



Terrafor workflow is in this order:

1. Write Code  => authpr the code using any IDE or text editor of choice
2. Plan        => Compare code against state
3. Apply       => Appies changes and record results

Once you have written your code, we can proceed to initializing it.
# Lets now initialize our configuration and deploy the infrastructure. Do so by running the below:

1. Change into working directory with terraform configuration

    $ cd my-stuff/terraform/basic/02-deploy-infra/base_web_app/

2. Initialize your configuration. You should now see a .terraform.lock.hcl file and .terraform folder/directory. 
   You can check the .terraform.lock.hcl into a repo so that anyone cloning it can use the  same configurations if they desire

    $ terraform init

3. Plan our deployment: Terraform Plan loads the configuration from the working directory, loads state data, 
   compares state and configuration data, and creates an execution plan. You can save the plan with the '-out' flag
    to a file (does not need to neccessary have the .tfplan extension) and use the saved plan for our terraform apply stage.
    You should now see the plan file m1.tfplan. The plan has different symbols shown below:
        + = creation
        - = deletion
        ~ = modification
    You see an output of all the resources to be created with + sign and a summary of total changes to be made at the  end of the o/p

   $ terraform plan -out m1.tfplan

        data.aws_ssm_parameter.amzn2_linux: Reading...
        data.aws_ssm_parameter.amzn2_linux: Read complete after 0s [id=/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2]
        Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
        + create
        ...
        ...
        ...
        Plan: 7 to add, 0 to change, 0 to destroy.
        Saved the plan to: m1.tfplan
        ...
        ...

    Note that only Terraform can read the Plan file, which is the basically the output of 'terraform plan' from
    the previous step. You can sen this file to someone to review it before you apply it to your infrastructure.
    To read the file run:

    $ terraform show m1.tfplan

4. Terraform Apply accepts the  saved plan, executes changes from the plan, updates state data contents, and generates a plan if none exist. 
   Do either of the below:

   $ terraform apply   [will genrate a plan file and prompt you to accept before apply your changes]

   $ terraform apply m1.tfplan   [uses my already generated plan file]

   Two files should now appear that you will learn more about later:
    - terraform.tfstate
    - terraform.tfstate.backup

Note that if 'terraform apply' throws an error but some resources have been deployed and you correct the source of the error, your plan file becomes stale.
You will need to run 'terraform plan -out m1.tfplan' again to add the change to the plan which removes the error from the plan file and will now execute successfully

5. Terraform destroy deletes or destroys resources from state. Use this with *caution*. 'terraform destroy' is an alias 'terraform apply -destroy'
   It creates a Plan for the  destroy action and prompts you to accept or decline, indicating all resources to be remove with the - sign, b4 moving ahead based on you action.
   When prompted in this case we enter 'yes' to accept and deleted all resources we just created

   $ terraform destroy

