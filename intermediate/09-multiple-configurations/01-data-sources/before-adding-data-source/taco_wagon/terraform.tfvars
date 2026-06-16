# Example terraform.tfvars file for Globomantics scenario
# Copy this file to terraform.tfvars and update with your values

company_name       = "globomantics"
environment        = "dev"
aws_region         = "us-east-1"
availability_zones = ["us-east-1a","us-east-1b"] # Use M1 commands
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t3.micro"
instance_ami_id    = "ami-0517aaaee33d8b971"
