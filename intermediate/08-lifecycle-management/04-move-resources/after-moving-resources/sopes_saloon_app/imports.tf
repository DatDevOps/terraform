locals {
  instance_id                 = "INSTANCE_ID_FROM_OUTPUT"
  security_group_egress_rule  = "SECURITY_GROUP_EGRESS_RULE_ID_FROM_OUTPUT"
  security_group_id           = "SECURITY_GROUP_ID_FROM_OUTPUT"
  security_group_ingress_rule = "SECURITY_GROUP_INGRESS_RULE_ID_FROM_OUTPUT"
}

import {
  id = local.instance_id
  to = aws_instance.web
}

import {
  id = local.security_group_id
  to = aws_security_group.main
}

import {
  id = local.security_group_ingress_rule
  to = aws_vpc_security_group_ingress_rule.http_access
}

import {
  id = local.security_group_egress_rule
  to = aws_vpc_security_group_egress_rule.all_outbound
}