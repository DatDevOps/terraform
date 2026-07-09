output "vpc_id" {
  description = "The ID of the VPC created by this module."
  value       = module.vpc.vpc_id
}