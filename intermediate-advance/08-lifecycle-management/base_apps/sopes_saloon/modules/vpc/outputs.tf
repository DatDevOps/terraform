# VPC ID
output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

# Public Subnet IDs
output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

# Internet Gateway ID
output "internet_gateway_id" {
    description = "The ID of the Internet Gateway."
    value       = aws_internet_gateway.main.id
}

# Public Route Table ID
output "public_route_table_id" {
  description = "The ID of the public route table."
  value       = aws_route_table.public.id
}