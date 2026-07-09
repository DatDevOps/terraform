provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for common tags
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = var.team
    Owner       = coalesce(var.owner, var.team)
  }
  name_prefix = lower(format("%s-%s", var.team, var.environment))

  #Added module exercise local values
  ingress_rules = [
    {
      from_port   = var.environment == "production" ? 8080 : 80
      to_port     = var.environment == "production" ? 8080 : 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = var.environment == "production" ? 8443 : 443
      to_port     = var.environment == "production" ? 8443 : 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  buckets = ["logs", "app-data", "backups"]
  # adds ["media"] +  ["logs", "app-data", "backups"] = ["logs", "app-data", "backups", "media"]
  bucket_prefixes = concat(local.buckets, var.additional_buckets)

}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = format("%s-vpc", local.name_prefix)
  })
}

## no longer need because of the for-each loop on the aws_subnet.public resource
# resource "aws_subnet" "public_1" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(var.vpc_cidr, 8, 0)
#   availability_zone = data.aws_availability_zones.available.names[0]

#   tags = merge(local.common_tags, {
#     Name = format("%s-public1", local.name_prefix)
#   })
# }

# resource "aws_subnet" "public_2" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
#   availability_zone = data.aws_availability_zones.available.names[1]

#   tags = merge(local.common_tags, {
#     Name = format("%s-public2", local.name_prefix)
#   })
# }

# resource "aws_subnet" "public_3" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
#   availability_zone = data.aws_availability_zones.available.names[2]

#   tags = merge(local.common_tags, {
#     Name = format("%s-public3", local.name_prefix)
#   })
# }

resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = format("%s-public-%s", local.name_prefix, (count.index + 1))
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(local.common_tags, {
    Name = format("%s-igw", local.name_prefix)
  })

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = format("%s-rtb", local.name_prefix)
  })
}
## no longer need because of the for-each loop on the aws_route_table_association resource
# resource "aws_route_table_association" "public_1" {
#   subnet_id      = aws_subnet.public_1.id
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_route_table_association" "public_2" {
#   subnet_id      = aws_subnet.public_2.id
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_route_table_association" "public_3" {
#   subnet_id      = aws_subnet.public_3.id
#   route_table_id = aws_route_table.public.id
# }

resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      protocol    = ingress.value.protocol
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = format("%s-web-sg", local.name_prefix)
  })
}

## no longer need because of the dynamic ingress block on the aws_security_group.web resource
# resource "aws_security_group" "web" {
#   description = "Security group for web servers"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     protocol    = "tcp"
#     from_port   = var.environment == "production" ? 8080 : 80
#     to_port     = var.environment == "production" ? 8080 : 80
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(local.common_tags, {
#     Name = format("%s-web-sg", local.name_prefix)
#   })
# }

data "aws_ssm_parameter" "amazon_linux_2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2_ami.value
  instance_type               = var.environment == "production" ? "t3.small" : "t3.micro"
  subnet_id                   = aws_subnet.public[0].id # reference first public subnet in for-each created subnets
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  monitoring                  = var.environment == "production" ? true : false
  user_data = templatefile("${path.module}/templates/user_data.tftpl", {
    company     = var.company
    environment = var.environment
    team        = var.team
  })

  tags = merge(local.common_tags, {
    Name   = format("%s-web-instance", local.name_prefix)
    Backup = var.environment == "production" ? "Daily" : "Weekly"
  })

}

# module exercise additions
resource "aws_s3_bucket" "web" {
  for_each = toset(local.bucket_prefixes) # Sets of unique bucket values used to create

  bucket_prefix = format("%s-%s-", local.name_prefix, each.value)
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "web" {
  for_each = toset(local.bucket_prefixes)   # Sets of unique bucket values 
  bucket   = aws_s3_bucket.web[each.key].id # bucket reference

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
