company             = "Globomantics"
team                = "Taco-Wagon"
public_subnet_count = 3
additional_buckets  = ["media"] # adds to the list of buckets defined in the local variable
application_config = {
  instance_count         = 2
  instance_type          = "t3.micro"
  instance_port          = 80
  instance_protocol      = "TCP"
  load_balancer_port     = 80
  load_balancer_protocol = "TCP"
  health_check = {
    path     = "/"
    port     = 80
    protocol = "HTTP"
  }
}

# module exercise requirement
app_password_version = 0
## uncomment below to force new secret creation and comment out 'app_password_version = 0' to test
# app_password_version = 1 
