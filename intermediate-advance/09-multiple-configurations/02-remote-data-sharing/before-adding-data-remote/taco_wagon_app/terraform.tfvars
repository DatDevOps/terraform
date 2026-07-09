# Example terraform.tfvars file for Globomantics scenario
# Copy this file to terraform.tfvars and update with your values

company_name  = "globomantics"
environment   = "dev"
aws_region    = "us-east-1"
instance_type = "t3.micro"
### We will pass this value later throught terraform remote state data source, but you can set it here for now
vpc_id            = "vpc-0df6f054d686846db"
public_subnet_ids = ["subnet-0d420c42c01863600", "subnet-09d7ace2af98612af"]