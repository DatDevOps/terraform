provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  naming_prefix = "taco-wagon-${var.environment}-"
}

## Networking Resources

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_range
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.naming_prefix}vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.naming_prefix}igw"
  }
}

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_ranges : idx => {
    cidr = cidr
    az   = data.aws_availability_zones.available.names[idx]
  } }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.naming_prefix}public-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.naming_prefix}public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

## EC2 Instance resources

data "aws_ssm_parameter" "amzn2_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "web" {
  ami                         = nonsensitive(data.aws_ssm_parameter.amzn2_linux.value)
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.main.id]
  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/user_data.sh",
    {
      environment = var.environment
  })

  tags = {
    Name        = "${local.naming_prefix}web"
    Environment = var.environment
  }

  # bucket must be created before instance
  depends_on = [aws_s3_bucket.logging]

  lifecycle {
    # you can only set it to attribute of the specified resource, not meta object
    ignore_changes = [tags]
  }
}

resource "aws_security_group" "main" {
  # name   = "taco-wagon-sg"
  name   = "${local.naming_prefix}sg"
  vpc_id = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_access" {
  security_group_id = aws_security_group.main.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_s3_bucket" "logging" {
  bucket_prefix = "${local.naming_prefix}logging-"

  # prevent the destruction of this bucket to avoid accidental data loss
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_s3_bucket" "cache" {
  bucket_prefix = "${local.naming_prefix}cache-"

  # causes the recreation of this resource each time the application version changes
  lifecycle {
    replace_triggered_by = [terraform_data.application_version]
  }
}

resource "terraform_data" "application_version" {
  input = var.application_version
}