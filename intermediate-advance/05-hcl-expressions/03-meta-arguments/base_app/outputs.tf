output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

# Use AWS provider function to parse ARN
output "vpc_arn_components" {
  description = "Parsed components of VPC ARN using provider-defined function"
  value       = provider::aws::arn_parse(aws_vpc.main.arn)
}

# added output as required by module-2 practical requirement
output "ec2_public_dns" {
  description = "Public DNS address of the web server"
  value       = "http://${aws_instance.web.public_dns}%{if var.environment == "production"}:8080%{endif}"
}
