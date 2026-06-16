# Main configuration for Globomantics web application infrastructure

provider "aws" {
  region  = var.aws_region
  profile = var.profile
}

# Local values for resource naming and common tags
locals {
  resource_prefix = "${var.company_name}-${var.environment}"

  allowed_env = ["dev", "staging", "prod"]

  common_tags = {
    Environment = var.environment
    Company     = var.company_name
    ManagedBy   = "Terraform"
    Project     = "WebApplication"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}


# VPC for the application
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-vpc"
  })
}

# Internet Gateway for public internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-igw"
  })
}

# Public subnets for resources that need internet access
resource "aws_subnet" "public" {
  count                   = var.availability_zones_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-public-subnet-${count.index + 1}"
    Type = "public"
  })
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-public-rt"
  })
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group for the web application instance
resource "aws_security_group" "web" {
  name        = "${local.resource_prefix}-web-sg"
  description = "Security group for web application instance"
  vpc_id      = aws_vpc.main.id

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
    content = templatefile("${path.module}/setup/templates/install_httpd.sh.tpl", {
      company_name = var.company_name
      environment  = var.environment
    })
  }
}

# EC2 instance for the web application
resource "aws_instance" "web" {
  ami           = data.aws_ami.amzn_linux2.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public[0].id

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data                   = data.cloudinit_config.user_data.rendered
  user_data_replace_on_change = true

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-web-server"
  })
}
