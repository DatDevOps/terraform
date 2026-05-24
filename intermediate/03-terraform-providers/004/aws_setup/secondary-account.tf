# Secondary Account Resources (security)

# Trust policy for the cross-account role
data "aws_iam_policy_document" "cross_account_role_trust_policy" {
  provider = aws.secondary
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.primary.account_id}:user/${var.primary_user_name}"
      ]
    }

    actions = ["sts:AssumeRole"]

  }
}

# Cross-account role that can be assumed from the primary account
resource "aws_iam_role" "cross_account_s3_role" {
  provider             = aws.secondary
  name                 = var.cross_account_role_name
  assume_role_policy   = data.aws_iam_policy_document.cross_account_role_trust_policy.json
  description          = "Cross-account role for S3 bucket creation from primary account"
  max_session_duration = 3600 # 1 hour

  tags = merge(var.tags, {
    Name        = var.cross_account_role_name
    Account     = "secondary"
    Description = "Cross-account role for S3 bucket creation from primary account"
    S3Prefix    = var.s3_prefix
  })
}

# Policy document for S3 bucket creation and management permissions in the secondary account
data "aws_iam_policy_document" "s3_bucket_permissions" {
  provider = aws.secondary
  # Allow all bucket actions, but only on buckets with the specified prefix
  statement {
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = ["arn:aws:s3:::$${aws:PrincipalTag/S3Prefix}*"]
  }
  # Allow listing all buckets (required for some S3 operations)
  statement {
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets"
    ]

    resources = ["arn:aws:s3:::*"]
  }
}

# IAM policy for S3 bucket permissions
resource "aws_iam_policy" "s3_bucket_permissions" {
  provider    = aws.secondary
  name        = "S3BucketCreationAndManagement"
  description = "Permissions for S3 bucket creation and management for buckets with specified prefix ${var.s3_prefix}"
  policy      = data.aws_iam_policy_document.s3_bucket_permissions.json

  tags = merge(var.tags, {
    Name        = "S3BucketCreationAndManagement"
    Account     = "secondary"
    Description = "S3 bucket permissions for cross-account role"
  })
}

# Attach the S3 bucket policy to the cross-account role
resource "aws_iam_role_policy_attachment" "cross_account_s3_permissions" {
  provider   = aws.secondary
  role       = aws_iam_role.cross_account_s3_role.name
  policy_arn = aws_iam_policy.s3_bucket_permissions.arn
}