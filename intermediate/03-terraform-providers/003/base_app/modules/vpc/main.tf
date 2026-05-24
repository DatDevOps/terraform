# data "aws_availability_zones" "available" {
#   state = "available"
# }

# locals {
#   # map each subnet to an availability zone in a round-robin fashion
#   subnet_to_az = {
#     for subnet in keys(var.network_info.public_subnets) : 
#       subnet => element(data.aws_availability_zones.available.names, index(keys(var.network_info.public_subnets), subnet) % length(data.aws_availability_zones.available.names))
#   }
# }

# hardcode region-specific AZs since the PluralSight AWS sandbox restricts us to us-east-1 and us-west-2 only, and the available AZs in those regions are consistent across accounts
locals {
  azs = var.region == "us-east-1" ? [
    "us-east-1a", "us-east-1b", "us-east-1c"
  ] : var.region == "us-west-2" ? [
    "us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"
  ] : []

  subnets = keys(var.network_info.public_subnets)

  subnet_to_az = {
    for idx, subnet in local.subnets :
    subnet => local.azs[idx % length(local.azs)]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.network_info.vpc_cidr
  enable_dns_hostnames = var.network_info.enable_dns_hostnames
  enable_dns_support   = var.network_info.enable_dns_support
  tags = {
    Name        = var.network_info.vpc_name
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.network_info.vpc_name}-igw"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  for_each                = var.network_info.public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = local.subnet_to_az[each.key]
  map_public_ip_on_launch = var.network_info.map_public_ip
  tags = {
    Name        = "${var.network_info.vpc_name}-public-${each.key}"
    Environment = var.environment
  }

}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.network_info.vpc_name}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
}