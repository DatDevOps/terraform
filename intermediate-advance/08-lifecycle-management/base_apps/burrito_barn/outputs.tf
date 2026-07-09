output "web_url" {
  description = "URL for web server."
  value       = "http://${aws_instance.web.public_dns}"
}

output "instance_id" {
  description = "Instance ID of the web server. Used by the update script."
  value       = aws_instance.web.id
}

output "aws_region" {
  description = "Region used for deployment. Used by the update script."
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID. Used by the update script."
  value       = aws_vpc.main.id
}

output "amzn2_linux" {
  description = "Amazon Linux 2 AMI ID. Used by the update script."
  value       = nonsensitive(data.aws_ssm_parameter.amzn2_linux.value)
}

output "security_group_id" {
  description = "Security group ID. Used by update script."
  value       = aws_security_group.main.id
}

output "public_route_table_id" {
  description = "Public Route table ID. Used by update script."
  value       = aws_route_table.public.id
}