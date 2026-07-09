#!/bin/bash

# Set your AWS region
export AWS_REGION="YOUR_REGION"

# Retrieve the list of AZs in the region, use ZoneName
aws ec2 describe-availability-zones --filters "Name=state,Values=available" --query "AvailabilityZones[*].{Name:ZoneName,State:State}" --output table

# Retrieve the Amazon Linux 2 AMI for the region
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].[ImageId,Name,CreationDate]" --output table
