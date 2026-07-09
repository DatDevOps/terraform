output "web_url" {
  description = "URL for web server."
  value       = "http://${aws_instance.web.public_dns}"
}

output "instance_id" {
  description = "Instance ID of the web server."
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security group ID for migration."
  value = aws_security_group.main.id
}

output "security_group_ingress_rule" {
  description = "Ingress rule for migration."
  value = aws_vpc_security_group_ingress_rule.http_access.id
}

output "security_group_egress_rule" {
  description = "Egress rule for migration."
  value = aws_vpc_security_group_egress_rule.all_outbound.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "vpc_id" {
  description = "VPC ID."
  value = aws_vpc.main.id
}