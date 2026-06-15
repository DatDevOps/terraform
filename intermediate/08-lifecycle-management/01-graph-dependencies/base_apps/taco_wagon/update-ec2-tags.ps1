# PowerShell script to add Team tag to the taco-wagon EC2 instance

# Get the instance ID and region from Terraform output
$instanceId = terraform output -raw instance_id

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($instanceId)) {
    Write-Error "Could not get instance_id from Terraform output"
    exit 1
}

$awsRegion = terraform output -raw aws_region

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($awsRegion)) {
    Write-Error "Could not get aws_region from Terraform output"
    exit 1
}

Write-Host "Found instance: $instanceId in region: $awsRegion"

# Add the Team tag to the instance
aws ec2 create-tags `
    --region $awsRegion `
    --resources $instanceId `
    --tags "Key=Team,Value=Taco Wagon"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Successfully added tag Team='Taco Wagon' to instance $instanceId"
} else {
    Write-Error "Failed to add tag to instance $instanceId"
    exit 1
}
