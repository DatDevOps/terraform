# VPC Flow Logs Module

This Terraform module creates and configures VPC Flow Logs with S3 bucket storage, including proper bucket policies, lifecycle management, and security configurations.

## Features

- **VPC Flow Logs**: Captures IP traffic information for network monitoring and troubleshooting
- **S3 Storage**: Secure S3 bucket with encryption and lifecycle policies
- **Cross-Account Support**: Supports capturing flow logs from VPCs in different AWS accounts
- **Lifecycle Management**: Automatic transition to cheaper storage classes and object expiration
- **Security**: Bucket policies, encryption, and access controls
- **Customizable**: Configurable traffic types, log formats, and aggregation intervals

## Architecture

The module creates the following resources:

1. **S3 Bucket** - Stores VPC flow log data with versioning enabled
2. **Bucket Policy** - Allows VPC Flow Logs service to write to the bucket
3. **Lifecycle Configuration** - Manages object transitions and retention
4. **VPC Flow Log** - Captures and delivers traffic data to S3

## Usage

### Basic Example

```terraform
module "vpc_flow_logs" {
  source = "./vpc_flow_logs"

  vpc_id           = "vpc-12345678"
  naming_prefix    = "my-project"
  bucket_id_suffix = "us-east-1-001"
  iam_role_arn     = "arn:aws:iam::123456789012:role/MyRole"

  providers = {
    aws.vpc_account = aws
  }

  tags = {
    Environment = "production"
    Project     = "networking"
  }
}
```

### Cross-Account Example

```terraform
module "vpc_flow_logs" {
  source = "./vpc_flow_logs"

  vpc_id              = "vpc-12345678"
  naming_prefix       = "my-project"
  bucket_id_suffix    = "us-east-1-001"
  iam_role_arn        = "arn:aws:iam::123456789012:role/MyRole"
  source_account_id   = "987654321098"  # Account where VPC resides
  
  providers = {
    aws.vpc_account = aws.source_account
  }

  tags = {
    Environment = "production"
    Project     = "networking"
  }
}
```

### Advanced Example with Custom Configuration

```terraform
module "vpc_flow_logs" {
  source = "./vpc_flow_logs"

  vpc_id                   = "vpc-12345678"
  naming_prefix            = "my-project"
  bucket_id_suffix         = "us-east-1-001"
  iam_role_arn             = "arn:aws:iam::123456789012:role/MyRole"
  
  # Flow log configuration
  traffic_type             = "REJECT"  # Only capture rejected traffic
  max_aggregation_interval = 60        # 1-minute aggregation
  flow_log_format          = "$${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${windowstart} $${windowend} $${action}"
  
  # S3 configuration
  kms_key_id               = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  s3_bucket_force_destroy  = false

  providers = {
    aws.vpc_account = aws
  }

  tags = {
    Environment = "production"
    Project     = "networking"
    Owner       = "network-team"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 6.0 |
| aws.vpc_account | ~> 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | The VPC ID to enable flow logs for | `string` | n/a | yes |
| naming_prefix | Prefix to use for naming resources (will be used for S3 bucket and flow logs) | `string` | n/a | yes |
| bucket_id_suffix | Suffix to append to the S3 bucket name for uniqueness | `string` | n/a | yes |
| iam_role_arn | The ARN of an existing IAM role to use for the bucket creation and management. Will be used for tagging. | `string` | n/a | yes |
| traffic_type | The type of traffic to capture (ALL, ACCEPT, or REJECT) | `string` | `"ALL"` | no |
| s3_bucket_force_destroy | Allow deletion of S3 bucket even if it contains objects (useful for testing) | `bool` | `true` | no |
| flow_log_format | The format for the flow logs (default AWS format or custom) | `string` | `null` | no |
| max_aggregation_interval | The maximum interval of time during which a flow of packets is captured and aggregated (60 or 600 seconds) | `number` | `600` | no |
| tags | A map of tags to assign to resources | `map(string)` | `{}` | no |
| kms_key_id | The KMS key ID to use for S3 bucket encryption (optional) | `string` | `null` | no |
| source_account_id | The AWS account ID where the VPC resides (if different from the account deploying this module) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| s3_bucket_name | Name of the S3 bucket created for VPC flow logs |
| s3_bucket_arn | ARN of the S3 bucket created for VPC flow logs |
| flow_log_id | The Flow Log ID |
| flow_log_arn | The ARN of the Flow Log |

## S3 Lifecycle Management

The module automatically configures S3 lifecycle rules to optimize storage costs:

1. **Standard IA**: Objects transition after 30 days
2. **Glacier**: Objects transition after 90 days  
3. **Deep Archive**: Objects transition after 365 days
4. **Expiration**: Objects are deleted after 7 years (2555 days)
5. **Cleanup**: Incomplete multipart uploads are removed after 7 days

## Security Features

### Encryption

- Server-side encryption with AES256 (default) or KMS (if `kms_key_id` provided)
- Bucket key enabled for KMS encryption to reduce costs

### Access Control

- Public access blocked on all levels
- Bucket policy restricts access to VPC Flow Logs service only
- Source account validation in bucket policy

### Versioning

- Object versioning enabled for data protection

## Flow Log Format

The module supports custom flow log formats. If not specified, AWS uses the default format. Example custom format:

```terraform
flow_log_format = "$${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${windowstart} $${windowend} $${action}"
```

Available fields include: `account-id`, `action`, `az-id`, `bytes`, `dstaddr`, `dstport`, `end`, `flow-direction`, `instance-id`, `interface-id`, `log-status`, `packets`, `pkt-dst-aws-service`, `pkt-dstaddr`, `pkt-src-aws-service`, `pkt-srcaddr`, `protocol`, `region`, `srcaddr`, `srcport`, `start`, `sublocation-id`, `sublocation-type`, `subnet-id`, `tcp-flags`, `traffic-path`, `type`, `version`, `vpc-id`, `windowend`, `windowstart`.

## Cross-Account Configuration

When deploying in a cross-account scenario:

1. Deploy this module in the account where you want to store logs
2. Set `source_account_id` to the account ID containing the VPC
3. Configure the `aws.vpc_account` provider to assume a role in the source account
4. Ensure the assumed role has permissions to create flow logs

## Cost Optimization

- Use `traffic_type = "REJECT"` to capture only blocked traffic and reduce volume
- Leverage lifecycle transitions to move data to cheaper storage classes
- Consider `max_aggregation_interval = 60` for detailed analysis vs. cost trade-offs
- Monitor S3 storage costs and adjust lifecycle rules as needed

## Troubleshooting

### Common Issues

1. **Flow log creation fails**: Ensure the VPC ID is valid and accessible
2. **S3 bucket policy errors**: Verify the source account ID is correct
3. **Cross-account access**: Check that the provider configuration and IAM roles are properly set up

### Validation

- VPC ID format validation ensures proper format (vpc-xxxxxxxx)
- Naming prefix validation enforces S3 bucket naming conventions
- Traffic type validation accepts only valid values (ALL, ACCEPT, REJECT)
