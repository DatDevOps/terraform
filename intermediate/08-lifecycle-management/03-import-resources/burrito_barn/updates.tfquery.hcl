list "aws_instance" "burrito_barn" {
    # Provider to use or provider alias if different from root module provider
    provider = aws
    # 

    # will return istance with tag: Team=BurritoBarn
    config {
        filter {
            name = "tag:Team"
            values = ["BurritoBarn"]
        }
    }
}

list "aws_subnet" "public_subnet" {
    provider = aws

    config {
        filter {
            name = "vpc-id"
            # uses the  value of the VPC created in Terraform, which is imported into the state file
            # otherwise you can hardcode the VPC ID here, but using the reference makes it more flexible and less error-prone
            values = [aws_vpc.main.id]
        }
    }
}