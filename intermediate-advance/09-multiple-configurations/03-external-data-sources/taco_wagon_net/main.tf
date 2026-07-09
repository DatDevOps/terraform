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

# Store the VPC ID and public subnet IDs in the SSM Parameter Store for use by other configurations
resource "aws_ssm_parameter" "vpc_id" {
  name           = "/taco-wagon-networking/${var.environment}/vpc-id"
  description    = "VPC ID for the Taco Wagon app"
  type           = "String"
  insecure_value = aws_vpc.main.id

  tags = {
    environment = "development"
    application = "taco-wagon"
  }
}

resource "aws_ssm_parameter" "public_subnets_ids" {
  name           = "/taco-wagon-networking/${var.environment}/public-subnet-ids"
  description    = "Public Subnet IDs for the Taco Wagon app"
  type           = "StringList"
  insecure_value = join(",", aws_subnet.public[*].id)

  tags = {
    environment = var.environment
    application = "taco-wagon"
  }
}