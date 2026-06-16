output "web_instance_id" {
  description = "ID of the web server instance"
  value       = aws_instance.web.id
}

output "web_instance_public_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.web.public_ip
}

output "application_url" {
  description = "URL to access the web application"
  value       = "http://${aws_instance.web.public_ip}"
}
