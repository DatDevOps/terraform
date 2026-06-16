#!/bin/bash

# Set your AWS region
export AWS_REGION="us-east-1"

# Retrieve the list of AZs in the region, use ZoneName
aws ec2 describe-availability-zones --filters "Name=state,Values=available" --query "AvailabilityZones[*].{Name:ZoneName,State:State}" --output table

    -----------------------------
    | DescribeAvailabilityZones |
    +-------------+-------------+
    |    Name     |    State    |
    +-------------+-------------+
    |  us-east-1a |  available  |
    |  us-east-1b |  available  |
    |  us-east-1c |  available  |
    |  us-east-1d |  available  |
    |  us-east-1e |  available  |
    |  us-east-1f |  available  |
    +-------------+-------------+

# Retrieve the Amazon Linux 2 AMI for the region
aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].[ImageId,Name,CreationDate]" --output table
    
    ---------------------------------------------
    |              DescribeImages               |
    +-------------------------------------------+
    |  ami-0517aaaee33d8b971                    |
    |  amzn2-ami-hvm-2.0.20260615.0-x86_64-gp2  |
    |  2026-06-11T21:26:44.000Z                 |
    +-------------------------------------------+