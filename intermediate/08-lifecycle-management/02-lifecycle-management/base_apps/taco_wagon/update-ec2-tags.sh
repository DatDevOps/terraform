#!/bin/bash
# Bash script to add Team tag to the taco-wagon EC2 instance

# Get the instance ID and region from Terraform output
instance_id=$(terraform output -raw instance_id)

if [ -z "$instance_id" ]; then
    echo "Error: Could not get instance_id from Terraform output" >&2
    exit 1
fi

aws_region=$(terraform output -raw aws_region)

if [ -z "$aws_region" ]; then
    echo "Error: Could not get aws_region from Terraform output" >&2
    exit 1
fi

echo "Found instance: $instance_id in region: $aws_region"

# Add the Team tag to the instance
aws ec2 create-tags \
    --region "$aws_region" \
    --resources "$instance_id" \
    --tags "Key=Team,Value=Taco Wagon" --profile my-sandbox

if [ $? -eq 0 ]; then
    echo "Successfully added tag Team='Taco Wagon' to instance $instance_id"
else
    echo "Error: Failed to add tag to instance $instance_id" >&2
    exit 1
fi
