terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    key    = "nacho_brigade/terraform.tfstate" 
    use_lockfile = true # Enable state locking to prevent concurrent modifications
    # dynamodb_table = <ddb_table_name> # DynamoDB table for state locking. Now deprecated in favor of use_lockfile
    profile = "my-sandbox"
  }  

  required_version = ">= 1.5"
}