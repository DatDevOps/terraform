resource "aws_lb" "web" {
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = format("%s-nlb", local.name_prefix)
  })
}

resource "aws_lb_target_group" "web" {
  port        = var.application_config.instance_port
  protocol    = var.application_config.instance_protocol
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol = var.application_config.health_check.protocol
    port     = var.application_config.health_check.port
    path     = var.application_config.health_check.path
  }

  tags = merge(local.common_tags, {
    Name = format("%s-nlb-tg", local.name_prefix)
  })
}

resource "aws_lb_target_group_attachment" "nlb_targets" {
  count = var.application_config.instance_count

  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web[count.index].id
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.web.arn
  port              = var.application_config.load_balancer_port
  protocol          = var.application_config.load_balancer_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
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

data "aws_ssm_parameter" "amazon_linux_2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "web" {
  count                  = var.application_config.instance_count
  ami                    = data.aws_ssm_parameter.amazon_linux_2_ami.value
  instance_type          = var.application_config.instance_type
  subnet_id              = aws_subnet.public[count.index % var.public_subnet_count].id # see modulo note below
  vpc_security_group_ids = [aws_security_group.web.id]
  monitoring             = var.application_config.monitoring
  user_data = templatefile("${path.module}/templates/user_data.tftpl", {
    company     = var.company
    environment = var.environment
    team        = var.team
  })

  tags = merge(local.common_tags, {
    Name   = format("%s-web-instance-%s", local.name_prefix, (count.index + 1))
    Backup = var.environment == "production" ? "Daily" : "Weekly"
  })

}


# NOTE ON SUBNET ASSIGNMENT WITH MODULO

# Example 1:

# var.public_subnet_count = 2
# subnets:
# aws_subnet.public[0] = subnet-a
# aws_subnet.public[1] = subnet-b
# If instance_count = 5, Terraform assigns:

# instance 0: 0 % 2 = 0 -> subnet-a
# instance 1: 1 % 2 = 1 -> subnet-b
# instance 2: 2 % 2 = 0 -> subnet-a
# instance 3: 3 % 2 = 1 -> subnet-b
# instance 4: 4 % 2 = 0 -> subnet-a
# So the pattern is: a, b, a, b, a.

# Example 2:

# var.public_subnet_count = 3
# subnets:
# [0] = subnet-a
# [1] = subnet-b
# [2] = subnet-c
# If instance_count = 8, then:

# instance 0: 0 % 3 = 0 -> subnet-a
# instance 1: 1 % 3 = 1 -> subnet-b
# instance 2: 2 % 3 = 2 -> subnet-c
# instance 3: 3 % 3 = 0 -> subnet-a
# instance 4: 4 % 3 = 1 -> subnet-b
# instance 5: 5 % 3 = 2 -> subnet-c
# instance 6: 6 % 3 = 0 -> subnet-a
# instance 7: 7 % 3 = 1 -> subnet-b
# Pattern: a, b, c, a, b, c, a, b.