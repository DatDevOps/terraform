#!/bin/bash
# Bash script to create an additional public subnet and EC2 instance
# Uses Terraform outputs for configuration values

set -e

# Colors for output
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
MY_AWS_PROFILE=" --profile my-sandbox"

# Get Terraform outputs
tfOutput=$(terraform output -json)

region=$(echo "$tfOutput" | jq -r '.aws_region.value')
vpcId=$(echo "$tfOutput" | jq -r '.vpc_id.value')
ami=$(echo "$tfOutput" | jq -r '.amzn2_linux.value')
securityGroupId=$(echo "$tfOutput" | jq -r '.security_group_id.value')
routeTableId=$(echo "$tfOutput" | jq -r '.public_route_table_id.value')

echo -e "${CYAN}Using configuration from Terraform outputs:${NC}"
echo "  Region: $region"
echo "  VPC ID: $vpcId"
echo "  AMI: $ami"
echo "  Security Group ID: $securityGroupId"
echo "  Route Table ID: $routeTableId"

# Get available AZs in the region
az=$(aws ec2 describe-availability-zones \
    --region "$region" \
    --query "AvailabilityZones[0].ZoneName" \
    --output text $MY_AWS_PROFILE)

echo -e "\n${CYAN}Using Availability Zone: $az${NC}"

# Create the subnet with a CIDR that doesn't conflict with existing subnets
# Using 10.0.10.0/24 as an additional subnet range
subnetCidr="10.0.10.0/24"

echo -e "\n${YELLOW}Creating public subnet with CIDR $subnetCidr...${NC}"
subnetId=$(aws ec2 create-subnet \
    --region "$region" \
    --vpc-id "$vpcId" \
    --cidr-block "$subnetCidr" \
    --availability-zone "$az" \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=burrito-barn-additional-public}]' \
    --query 'Subnet.SubnetId' \
    --output text \
    $MY_AWS_PROFILE)

echo -e "${GREEN}Created subnet: $subnetId${NC}"

# Enable auto-assign public IP on the subnet
echo -e "${YELLOW}Enabling auto-assign public IP on subnet...${NC}"
aws ec2 modify-subnet-attribute \
    --region "$region" \
    --subnet-id "$subnetId" \
    --map-public-ip-on-launch  $MY_AWS_PROFILE

# Associate the subnet with the public route table
echo -e "${YELLOW}Associating subnet with public route table...${NC}"
aws ec2 associate-route-table \
    --region "$region" \
    --subnet-id "$subnetId" \
    --route-table-id "$routeTableId"  $MY_AWS_PROFILE > /dev/null

echo -e "${GREEN}Route table associated successfully${NC}"

# Create EC2 instance in the new subnet
echo -e "\n${YELLOW}Creating EC2 instance in the new subnet...${NC}"
instanceId=$(aws ec2 run-instances \
    --region "$region" \
    --image-id "$ami" \
    --instance-type t3.micro \
    --subnet-id "$subnetId" \
    --security-group-ids "$securityGroupId" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=burrito-barn-app},{Key=Environment,Value=dev},{Key=Team,Value=BurritoBarn}]' \
    --query 'Instances[0].InstanceId' \
    --output text $MY_AWS_PROFILE)

echo -e "${GREEN}Created EC2 instance: $instanceId${NC}"

# Wait for instance to be running
echo -e "\n${YELLOW}Waiting for instance to be running...${NC}"
aws ec2 wait instance-running --region "$region" --instance-ids "$instanceId" $MY_AWS_PROFILE
echo -e "${GREEN}Instance is now running!${NC}"

echo -e "\n${CYAN}Additional resources created successfully!${NC}"
