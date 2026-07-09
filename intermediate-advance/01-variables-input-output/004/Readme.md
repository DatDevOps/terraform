
<!--02 Output Variable -->

These values are return when a resource is deployed. Usecases include
- Display at the terminal window
    1. Displayed after 'terraform apply'
    2. Display output in state by using 'terraform output'
    3. Output can be in Human readable form, JSON , or RAW
- Pass information to parent module
- Data source for other configurations

outputs in a child module or data source for other configurations can be passed to the parent using 'terraform_remote_state' and 'terraform output' to get output from a remote state and local state respectively. Only outputs variables are available and not local input variables, local values and other resource values are out of scope


<!-- Output Syntax -->

    output "name_label" {
        value = value
        description = "string"
    }

Examples:

    output "vpc_id" {
        value = aws_vpc.main.id
        description = "VPC ID network deployment"
    }

[sensitive = true] means not printed to terminal. The default is false

    output "vpc_id" {
        value = aws_vpc.main.id
        description = "VPC ID network deployment"
        sensitive = true
    }

[ephemeral = true] means not printed to terminal and made sensitive wherever a parent modules references the value.  They are not written to state and It can only be applied to child modules because parent modules outputs are written  to state. The default is false

    output "db_password" {
        value = random_password.db_pass.result
        description = "Password to use for DB admin"
        ephemeral = true
    }

[depends_on = [aws_internet_gateway.main]] means aws_internet_gateway.main will be created before this value is output

    output "vpc_id" {
        value = aws_vpc.main.id
        description = "VPC ID network deployment"
        sensitive = true
        depends_on = [aws_internet_gateway.main]
    }    

[precondition{...}] means if the precondition is not met, terraform does not update the output in state

    output "instance_public_dns" {
        value = aws_instance.app.public.dns
        description = "Public dns of instance"
        precondition{
            condition = aws_instance.app.state == "running"
            error_message = "The instance must be running"
        }
    }  

Now let us add outputs using all/some of the above
-   Define outputs for S3 module
-   Print S3 module outputs to terminal
-   Add public DNS address of EC2 instance
-   Add IDs of the public subnets
-   Mark public subnet IDs and VPC ID as sentive      


Now go ahead and add the local variables to the main.tf file

Run the below if you have not already done so:

On the commandline, set an environment (must be prefixed like this TF_VAR_<VARIABLE_KEY>) variable to hold the value of the api_key using below

   $ export TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Linux] 
   
   OR

   $ $env:TF_VAR_api_key="BG^&*UJHJU*&^YUJHY&U"  [Windows]

Once you are done, validate and format your code and the apply the changes using the below:

    $ cd my-stuff/terraform/intermediate/01-variables-output/003/base_app

    $ terraform init [only if you have not done this before. But I have done so and skipping it]

    $ terraform fmt -check

    $ terraform fmt 
    
    $ terraform fmt -check [should return nothing now]

    $ terraform validate [proceed if successful]

    $ terraform plan -out m3.tfplan [check to see all resource name now follow the requirement requested above]

    $ terraform apply m3.tfplan

Check various resource names and after which you should delete all resources    

    $ terraform apply m3.tfplan [you should get the below at the end of the terminal]

        Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

        Outputs:

        bucket_info = {
        "arn" = "arn:aws:s3:::burrito-barn-dev20260512232250625600000001"
        "id" = "burrito-barn-dev20260512232250625600000001"
        "policy" = "{\"Statement\":[{\"Action\":\"s3:GetObject\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::859616339147:role/burrito-barn-dev-role\"},\"Resource\":\"arn:aws:s3:::burrito-barn-dev20260512232250625600000001/*\"}],\"Version\":\"2012-10-17\"}"
        }
        ec2_public_dns = "ec2-100-53-31-36.compute-1.amazonaws.com"
        ec2_public_ip = "100.53.31.36"
        public_subnet_ids = <sensitive>
        vpc_id = <sensitive>   

    $ terraform output [displays all output to terminal again]

Note that the 'terraform output' displays sensitive info so you might want to pipe it to a file and not display it raw in a log

    $ terraform output -json [displays all output to terminal again in JSON.]

    $ terraform output  bucket_info  [displays the single whic is alread in JSON from above]

    $ terraform output ec2_public_dns [displays a single output in quotes]

    $ terraform output -raw ec2_public_dns [displays a single output without quotes]