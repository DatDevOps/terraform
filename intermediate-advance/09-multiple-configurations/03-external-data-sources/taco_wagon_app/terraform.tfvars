company_name  = "globomantics"
environment   = "dev"
aws_region    = "us-east-1"
instance_type = "t3.micro"
## Not needed since we're using the SSM parameter data source to retrieve the networking information
# network_bucket_config = {
#   bucket = "tacowagon-net20260616003241922400000002"
#   region = "us-east-1"
#   key    = "taco-wagon-net.tfstate"
#   profile = "my-sandbox"
# }

# Replacement for the above variable since we're now using SSM Parameter Store to share data between configurations
network_parameter_path = "/taco-wagon-networking"