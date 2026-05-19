# All repos: https://github.com/ned1313?tab=repositories&q=Terraform+state+fun&type=&language=&sort=

# Exercise file link for module: https://github.com/ned1313/Getting-Started-Terraform.git

# You can find the installer info for Terraform here:
# https://developer.hashicorp.com/terraform/downloads

# For windows you do install using 'winget'

    winget install Hashicorp.Terraform     [installs Terraform]
    
    
    winget upgrade Hashicorp.Terraform     [upgrades Terraform if you want to get the latest or specific version]

# Continue with  the below once you have completed your installation
# First we'll start by making sure Terraform is installed and check out the
# help command baked in to the cli.

    terraform version

    terraform -help

# Terraform follows the terraform <command> <subcommand> syntax
# Options use a single dash whether it's a single character option
# or full word.

    terraform plan -h