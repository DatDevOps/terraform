# Example terraform.tfvars file for Globomantics scenario
# Copy this file to terraform.tfvars and update with your values

company_name             = "globomantics"
environment              = "dev"
aws_region               = "us-east-1"
availability_zones_count = 2 #
vpc_cidr                 = "10.0.0.0/16"
instance_type            = "t3.micro"
## no longer need as we are using data source to get the latest AMI ID for our EC2 instance 
## and availability zones count is being used to determine how many subnets to create, 
## so we can remove the availability_zones variable and use the data source instead
# availability_zones = ["us-east-1a","us-east-1b"] # Use M1 commands
# instance_ami_id    = "ami-0517aaaee33d8b971"
