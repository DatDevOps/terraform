# _cleaned up code _generated__ by Terraform
resource "aws_subnet" "app_subnet" {
  cidr_block                                     = "10.0.10.0/24"
  map_public_ip_on_launch                        = true
  tags = {
    Name = "burrito-barn-additional-public"
  }

  vpc_id = aws_vpc.main.id
}

# __generated__ by Terraform
resource "aws_instance" "app_server" {
  ami                                  = nonsensitive(data.aws_ssm_parameter.amzn2_linux.value)
  instance_type                        = var.instance_type
  subnet_id                            = aws_subnet.app_subnet.id
  tags = {
    Environment = var.environment
    Name        = "burrito-barn-app"
    Team        = "BurritoBarn"
  }
  vpc_security_group_ids      = [aws_security_group.main.id]
}




# # __generated__ by Terraform
# # Please review these resources and move them into your main configuration files.

# # __generated__ by Terraform
# resource "aws_subnet" "app_subnet" {
#   assign_ipv6_address_on_creation                = false
#   availability_zone                              = "us-east-1a"
#   availability_zone_id                           = "use1-az1"
#   cidr_block                                     = "10.0.10.0/24"
#   customer_owned_ipv4_pool                       = null
#   enable_dns64                                   = false
#   enable_lni_at_device_index                     = 0
#   enable_resource_name_dns_a_record_on_launch    = false
#   enable_resource_name_dns_aaaa_record_on_launch = false
#   ipv6_cidr_block                                = null
#   ipv6_native                                    = false
#   map_customer_owned_ip_on_launch                = false
#   map_public_ip_on_launch                        = true
#   outpost_arn                                    = null
#   private_dns_hostname_type_on_launch            = "ip-name"
#   region                                         = "us-east-1"
#   tags = {
#     Name = "burrito-barn-additional-public"
#   }
#   tags_all = {
#     Name = "burrito-barn-additional-public"
#   }
#   vpc_id = "vpc-0dcf5f43dabfb7442"
# }

# # __generated__ by Terraform
# resource "aws_instance" "app_server" {
#   ami                                  = "ami-0517aaaee33d8b971"
#   associate_public_ip_address          = true
#   availability_zone                    = "us-east-1a"
#   disable_api_stop                     = false
#   disable_api_termination              = false
#   ebs_optimized                        = false
#   force_destroy                        = false
#   get_password_data                    = false
#   hibernation                          = false
#   instance_initiated_shutdown_behavior = "stop"
#   instance_type                        = "t3.micro"
#   ipv6_address_count                   = 0
#   ipv6_addresses                       = []
#   monitoring                           = false
#   placement_partition_number           = 0
#   private_ip                           = "10.0.0.183"
#   region                               = "us-east-1"
#   secondary_private_ips                = []
#   security_groups                      = []
#   source_dest_check                    = true
#   subnet_id                            = "subnet-011fbcb7aae0ccec7"
#   tags = {
#     Environment = "dev"
#     Name        = "burrito-barn-dev-web"
#     Team        = "BurritoBarn"
#   }
#   tags_all = {
#     Environment = "dev"
#     Name        = "burrito-barn-dev-web"
#     Team        = "BurritoBarn"
#   }
#   tenancy                     = "default"
#   user_data                   = "#! /bin/bash\nsudo amazon-linux-extras install -y nginx1\nsudo service nginx start\nsudo rm /usr/share/nginx/html/index.html\nsudo cat > /usr/share/nginx/html/index.html << 'WEBSITE'\n<html>\n<head>\n    <title>Burrito Barn Server - dev</title>\n</head>\n<body style=\"background-color:#1F778D\">\n    <p style=\"text-align: center;\">\n        <span style=\"color:#FFFFFF;\">\n            <span style=\"font-size:100px;\">Welcome to the dev website! Have a &#127791;</span>\n        </span>\n    </p>\n</body>\n</html>\nWEBSITE"
#   user_data_replace_on_change = null
#   volume_tags                 = null
#   vpc_security_group_ids      = ["sg-0cdd1ded3e4f0d59a"]
#   capacity_reservation_specification {
#     capacity_reservation_preference = "open"
#   }
#   cpu_options {
#     core_count       = 1
#     threads_per_core = 2
#   }
#   credit_specification {
#     cpu_credits = "unlimited"
#   }
#   enclave_options {
#     enabled = false
#   }
#   maintenance_options {
#     auto_recovery = "default"
#   }
#   metadata_options {
#     http_endpoint               = "enabled"
#     http_protocol_ipv6          = "disabled"
#     http_put_response_hop_limit = 1
#     http_tokens                 = "optional"
#     instance_metadata_tags      = "disabled"
#   }
#   primary_network_interface {
#     network_interface_id = "eni-055aa3d9b2e2d5826"
#   }
#   private_dns_name_options {
#     enable_resource_name_dns_a_record    = false
#     enable_resource_name_dns_aaaa_record = false
#     hostname_type                        = "ip-name"
#   }
#   root_block_device {
#     delete_on_termination = true
#     encrypted             = false
#     iops                  = 100
#     tags                  = {}
#     tags_all              = {}
#     throughput            = 0
#     volume_size           = 8
#     volume_type           = "gp2"
#   }
# }
