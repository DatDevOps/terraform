bucket_prefix = "burrito-barn"
instance_type = "t2.micro"
vpc_network_info = {
  vpc_name = "burrito-barn-vpc"
  vpc_cidr = "10.0.0.0/16"
  public_subnets = {
    subnet1 = "10.0.0.0/24"
    subnet2 = "10.0.1.0/24"
  }
}