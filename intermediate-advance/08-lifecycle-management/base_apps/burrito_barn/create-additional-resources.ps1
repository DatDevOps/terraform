# PowerShell script to create an additional public subnet and EC2 instance
# Uses Terraform outputs for configuration values

# Get Terraform outputs
$tfOutput = terraform output -json | ConvertFrom-Json

$region = $tfOutput.aws_region.value
$vpcId = $tfOutput.vpc_id.value
$ami = $tfOutput.amzn2_linux.value
$securityGroupId = $tfOutput.security_group_id.value
$routeTableId = $tfOutput.public_route_table_id.value

Write-Host "Using configuration from Terraform outputs:" -ForegroundColor Cyan
Write-Host "  Region: $region"
Write-Host "  VPC ID: $vpcId"
Write-Host "  AMI: $ami"
Write-Host "  Security Group ID: $securityGroupId"
Write-Host "  Route Table ID: $routeTableId"

# Get available AZs in the region
$azs = aws ec2 describe-availability-zones `
    --region $region `
    --query "AvailabilityZones[*].ZoneName" `
    --output json | ConvertFrom-Json

$az = $azs[0]
Write-Host "`nUsing Availability Zone: $az" -ForegroundColor Cyan

# Create the subnet with a CIDR that doesn't conflict with existing subnets
# Using 10.0.10.0/24 as an additional subnet range
$subnetCidr = "10.0.10.0/24"

Write-Host "`nCreating public subnet with CIDR $subnetCidr..." -ForegroundColor Yellow
$subnetResult = aws ec2 create-subnet `
    --region $region `
    --vpc-id $vpcId `
    --cidr-block $subnetCidr `
    --availability-zone $az `
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=burrito-barn-additional-public}]" `
    --output json | ConvertFrom-Json

$subnetId = $subnetResult.Subnet.SubnetId
Write-Host "Created subnet: $subnetId" -ForegroundColor Green

# Enable auto-assign public IP on the subnet
Write-Host "Enabling auto-assign public IP on subnet..." -ForegroundColor Yellow
aws ec2 modify-subnet-attribute `
    --region $region `
    --subnet-id $subnetId `
    --map-public-ip-on-launch

# Associate the subnet with the public route table
Write-Host "Associating subnet with public route table..." -ForegroundColor Yellow
aws ec2 associate-route-table `
    --region $region `
    --subnet-id $subnetId `
    --route-table-id $routeTableId | Out-Null

Write-Host "Route table associated successfully" -ForegroundColor Green

# Create EC2 instance in the new subnet
Write-Host "`nCreating EC2 instance in the new subnet..." -ForegroundColor Yellow
$instanceResult = aws ec2 run-instances `
    --region $region `
    --image-id $ami `
    --instance-type t3.micro `
    --subnet-id $subnetId `
    --security-group-ids $securityGroupId `
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=burrito-barn-app},{Key=Environment,Value=dev},{Key=Team,Value=BurritoBarn}]" `
    --output json | ConvertFrom-Json

$instanceId = $instanceResult.Instances[0].InstanceId
Write-Host "Created EC2 instance: $instanceId" -ForegroundColor Green

# Wait for instance to be running
Write-Host "`nWaiting for instance to be running..." -ForegroundColor Yellow
aws ec2 wait instance-running --region $region --instance-ids $instanceId
Write-Host "Instance is now running!" -ForegroundColor Green

Write-Host "`nAdditional resources created successfully!" -ForegroundColor Cyan