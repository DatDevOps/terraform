provider "aws" {
  region = var.region
}

locals {
  naming_prefix = "sopes-saloon-${var.environment}-"
}

data "aws_ssm_parameter" "amzn2_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# copied sopes-saloon main.tf of completed Practical-1 with chnages in referenced values to match the variables defined in this module
##########
resource "aws_instance" "web" {
  ami                         = nonsensitive(data.aws_ssm_parameter.amzn2_linux.value)
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_ids[0]
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
  vpc_id = var.vpc_id

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

# End of copy sopes-saloon main.tf of completed Practical-1
##############