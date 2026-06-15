output "web_url" {
  description = "URL for web server."
  value       = "http://${aws_instance.web.public_dns}"
}

output "instance_id" {
  description = "Instance ID of the web server. Used by the tag update script."
  value       = aws_instance.web.id
}

output "aws_region" {
  description = "Region used for deployment. Used by the tag update script."
  value       = var.region
}