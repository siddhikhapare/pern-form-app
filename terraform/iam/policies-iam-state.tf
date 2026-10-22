# ============================================================
# IAM Policies - IAM Management and Terraform State
# ============================================================

# ── IAM Policy (Limited - for creating EC2 roles) ─────────
resource "aws_iam_policy" "terraform_iam" {
  name        = "${var.project_name}-${var.environment}-terraform-iam-policy"
  description = "Terraform permissions for IAM (limited to project resources)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          # Roles
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
          "iam:ListRoles",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          
          # Role Policies
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          
          # Instance Profiles
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:ListInstanceProfileTags"
        ]
        Resource = [
          "arn:aws:iam::${local.account_id}:role/${var.project_name}-${var.environment}-*",
          "arn:aws:iam::${local.account_id}:instance-profile/${var.project_name}-${var.environment}-*"
        ]
      },
      {
        Sid    = "IAMPolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicies",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:ListPolicyTags"
        ]
        Resource = "arn:aws:iam::${local.account_id}:policy/${var.project_name}-${var.environment}-*"
      },
      {
        Sid    = "IAMServiceLinkedRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole",
          "iam:DeleteServiceLinkedRole",
          "iam:GetServiceLinkedRoleDeletionStatus"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/*"
      },
      {
        Sid    = "IAMReadOnly"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListUsers",
          "iam:GetAccountSummary",
          "iam:ListAccountAliases",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders"
        ]
        Resource = "*"
      },
      {
        Sid    = "PassRoleToServices"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::${local.account_id}:role/${var.project_name}-${var.environment}-*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ec2.amazonaws.com",
              "ecs.amazonaws.com",
              "lambda.amazonaws.com",
              "rds.amazonaws.com",
              "monitoring.rds.amazonaws.com",
              "autoscaling.amazonaws.com",
              "cloudwatch.amazonaws.com"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-iam-policy"
  }
}

# ── Terraform State Policy (S3 + DynamoDB) ─────────────────
resource "aws_iam_policy" "terraform_state" {
  name        = "${var.project_name}-${var.environment}-terraform-state-policy"
  description = "Terraform permissions for state management (S3 + DynamoDB)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      },
      {
        Sid    = "DynamoDBStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${var.terraform_state_lock_table}"
      },
      {
        Sid    = "KMSForStateEncryption"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn != "" ? [var.kms_key_arn] : ["*"]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-state-policy"
  }
}
