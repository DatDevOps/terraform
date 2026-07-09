output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}