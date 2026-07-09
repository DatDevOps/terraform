# resources to be removed from sopes_saloon module after moving to sopes_saloon_app module
removed {
  from = aws_instance.web

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_security_group.main

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_vpc_security_group_ingress_rule.http_access

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_vpc_security_group_egress_rule.all_outbound

  lifecycle {
    destroy = false
  }
}