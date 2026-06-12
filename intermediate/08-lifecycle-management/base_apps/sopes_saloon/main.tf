provider "aws" {
  region = var.region
}

locals {
  naming_prefix = "sopes-saloon-${var.environment}-"
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
}

resource "aws_security_group" "main" {
  name   = "${local.naming_prefix}sg"
  vpc_id = aws_vpc.main.id

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

## VPC Flow Logs to S3

resource "aws_s3_bucket" "flow_logs" {
  bucket_prefix = "${local.naming_prefix}flow-logs-"
  force_destroy = true

  tags = {
    Name = "${local.naming_prefix}flow-logs"
  }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_bucket_policy.json
}

data "aws_iam_policy_document" "flow_logs_bucket_policy" {
  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.flow_logs.arn]
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.flow_logs.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_flow_log" "main" {
  log_destination      = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id

  tags = {
    Name = "${local.naming_prefix}flow-log"
  }
}
