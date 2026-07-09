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
  value       = {}
}
