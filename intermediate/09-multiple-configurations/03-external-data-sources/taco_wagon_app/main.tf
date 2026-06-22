provider "aws" {
  region  = var.aws_region
  profile = var.profile
}

# Local values for resource naming and common tags
locals {
  resource_prefix = "${var.company_name}-${var.environment}"

  common_tags = {
    Environment = var.environment
    Company     = var.company_name
  }
}

## No longer needed since we are getting the vpc nad subnes info from SSM parameters instead of the network remote state
# referencing the network remote state to get VPC and subnet information
# data "terraform_remote_state" "net" {
#   backend = "s3"

#   config = var.network_bucket_config
# }

# Now we are getting the VPC and subnet information from SSM parameters instead of the network remote state, we can use a data source to retrieve those values
data "aws_ssm_parameter" "networking" {
  for_each = toset(["vpc-id", "public-subnet-ids"])

  name = "${var.network_parameter_path}/${var.environment}/${each.value}"
}

# Security group for the web application instance
resource "aws_security_group" "web" {
  name        = "${local.resource_prefix}-web-sg"
  description = "Security group for web application instance"
  # vpc_id      = data.terraform_remote_state.net.outputs.vpc_id
  vpc_id = data.aws_ssm_parameter.networking["vpc-id"].insecure_value


  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-web-sg"
  })
}

data "aws_ami" "amzn_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Cloud init data source
data "cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/templates/install_httpd.sh.tpl", {
      company_name = var.company_name
      environment  = var.environment
    })
  }
}

# EC2 instance for the web application
resource "aws_instance" "web" {
  ami           = data.aws_ami.amzn_linux2.id
  instance_type = var.instance_type
  # reference the public subnet from the network remote state
  # subnet_id = data.terraform_remote_state.net.outputs.public_subnet_ids[0]
  subnet_id = split(",", data.aws_ssm_parameter.networking["public-subnet-ids"].insecure_value)[0]


  vpc_security_group_ids = [aws_security_group.web.id]

  user_data                   = data.cloudinit_config.user_data.rendered
  user_data_replace_on_change = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-web-server"
  })
}
