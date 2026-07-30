# AWS Cross-Account Setup

This Terraform configuration sets up the necessary IAM roles and policies across two AWS accounts to enable an existing user in the primary account to assume a role in the secondary account with permissions for:

- **S3 Bucket Management**: Create, manage, and apply policies to S3 buckets (with creator-only access)

**Important**: This configuration assumes you have an existing IAM user in the primary account with the necessary permissions. The configuration will only add the cross-account role assumption policy to this existing user.

## Account Structure

* **sopes-saloon**: Primary account for deploying resources
* **security**: Secondary account where cross-account role will be assumed

## Prerequisites

1. **AWS CLI configured** with profiles for both accounts
2. **Terraform** installed (version >= 1.0)
3. **Administrative access** to both AWS accounts
4. **Existing IAM user** in the primary account to receive the role assignment

## AWS Profile Setup

Create AWS profiles for both accounts using the AWS CLI:

```bash
aws configure --profile "sopes-saloon"
aws configure --profile "security"
```

## Configuration Files

This Terraform configuration includes:

- `versions.tf`: Provider version constraints
- `variables.tf`: Variable definitions with validation
- `main.tf`: Provider configuration and account validation
- `primary-account.tf`: Resources for the primary account
- `secondary-account.tf`: Resources for the secondary account
- `outputs.tf`: Important output values
- `terraform.tfvars.example`: Example variables file

## Deployment Instructions

1. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`** with the existing user and desired role name:
   ```hcl
   cross_account_role_name = "S3BucketManagementRole"
   primary_user_name       = "existing-user" # Name of existing IAM user in primary account
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the planned changes:**
   ```bash
   terraform plan -out="s3role.tfplan"
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply s3role.tfplan
   ```

## Resources Created

### Primary Account

- **IAM Policy**: `AssumeS3CreationRole` - Allows the existing user to assume the cross-account role
- **Policy Attachment**: Attaches the assume role policy to the existing IAM user

### Secondary Account

- **IAM Role**: `S3BucketManagementRole` - Cross-account role with comprehensive permissions
- **IAM Policy**: `S3BucketCreationAndManagement` - S3 bucket creation and management permissions (creator-only access)

## Key Features

### S3 Bucket Management

The cross-account role includes S3 permissions that allow:

- Creating new S3 buckets
- Managing bucket contents, policies, and lifecycle configurations
- Only buckets with a specific naming prefix can be managed by the role

### Security Features

- **Creator-only Access**: S3 buckets must have a specific prefix to be managed by the role
- **Cross-Account Isolation**: Role operates in secondary account but is assumed from primary
- **Time-Limited Sessions**: Role sessions expire after 1 hour

## Outputs

The configuration provides several important outputs:

- Existing IAM user and role ARNs
- S3 bucket policy information

## Cleanup

To remove all created resources:

```bash
terraform destroy
```
