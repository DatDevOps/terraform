## Networking Resources
module "dr_vpc" {
  source       = "./modules/vpc"
  environment  = var.environment
  region       = var.dr_region
  network_info = var.network_info

  # set the provider to use the DR region and alias defined in providers.tf
  providers = {
    aws = aws.dr
  }
}
