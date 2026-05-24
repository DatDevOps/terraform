region = "us-east-1"
network_info = {
  vpc_name = "sopes-saloon"
  vpc_cidr = "10.0.0.0/16"
  public_subnets = {
    subnet_1 = "10.0.0.0/24"
  }
}

# enter the ARN of the role arn created in the security account for creating S3 bucket for VPC flow logs
# shouldbe like arn:aws:iam::<account_id>:role/S3BucketManagementRole
security_role_arn = "SET_WITH_VALUE"