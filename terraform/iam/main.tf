# ============================================================
# IAM Module - Production-Grade Setup
# ============================================================
#
# This module creates:
#   1. Terraform Execution Role (assumed by CI/CD or users)
#   2. EC2 Instance Role (for Web/App tier instances)
#   3. Custom policies following least-privilege principle
#   4. Optional: IAM User for CI/CD pipelines
#
# Architecture:
#   CI/CD User --> AssumeRole --> Terraform Execution Role
#                                        |
#                                        v
#                              Custom Policies (VPC, EC2, RDS, etc.)
#
# ============================================================

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================
# 1. TERRAFORM EXECUTION ROLE
# ============================================================
# This role is assumed by CI/CD pipelines or developers
# to execute Terraform commands with least-privilege access

resource "aws_iam_role" "terraform_execution" {
  name        = "${var.project_name}-${var.environment}-terraform-execution-role"
  description = "Role assumed by CI/CD or developers to execute Terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_role_arns
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      },
      # Allow GitLab CI/CD OIDC (if using GitLab runners)
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${local.account_id}:oidc-provider/gitlab.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "gitlab.com:sub" = "project_path:${var.gitlab_project_path}:ref_type:branch:ref:main"
          }
        }
      }
    ]
  })

  max_session_duration = 3600  # 1 hour max session

  tags = {
    Name        = "${var.project_name}-${var.environment}-terraform-execution-role"
    Purpose     = "Terraform Infrastructure Deployment"
    Environment = var.environment
  }
}

# ============================================================
# 2. EC2 INSTANCE ROLE (for Web/App tier)
# ============================================================
# This role is attached to EC2 instances via instance profile

resource "aws_iam_role" "ec2_instance" {
  name        = "${var.project_name}-${var.environment}-ec2-instance-role"
  description = "Role for EC2 instances in Web and App tiers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-instance-role"
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name
}

# ============================================================
# 3. CI/CD IAM USER (Optional - for non-OIDC setups)
# ============================================================

resource "aws_iam_user" "cicd" {
  count = var.create_cicd_user ? 1 : 0

  name = "${var.project_name}-${var.environment}-cicd-user"
  path = "/terraform/"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cicd-user"
    Purpose     = "CI/CD Pipeline - Terraform Deployment"
    Environment = var.environment
  }
}

# Policy to allow CI/CD user to assume Terraform execution role
resource "aws_iam_user_policy" "assume_terraform_role" {
  count = var.create_cicd_user ? 1 : 0

  name = "AssumeTerrformExecutionRole"
  user = aws_iam_user.cicd[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = aws_iam_role.terraform_execution.arn
    }]
  })
}

# ============================================================
# 4. ATTACH POLICIES TO TERRAFORM EXECUTION ROLE
# ============================================================

resource "aws_iam_role_policy_attachment" "terraform_vpc" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_vpc.arn
}

resource "aws_iam_role_policy_attachment" "terraform_ec2" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_ec2.arn
}

resource "aws_iam_role_policy_attachment" "terraform_alb" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_alb.arn
}

resource "aws_iam_role_policy_attachment" "terraform_asg" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_asg.arn
}

resource "aws_iam_role_policy_attachment" "terraform_rds" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_rds.arn
}

resource "aws_iam_role_policy_attachment" "terraform_cloudfront" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_cloudfront.arn
}

resource "aws_iam_role_policy_attachment" "terraform_route53" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_route53.arn
}

resource "aws_iam_role_policy_attachment" "terraform_acm" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_acm.arn
}

resource "aws_iam_role_policy_attachment" "terraform_monitoring" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_monitoring.arn
}

resource "aws_iam_role_policy_attachment" "terraform_iam" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_iam.arn
}

resource "aws_iam_role_policy_attachment" "terraform_state" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = aws_iam_policy.terraform_state.arn
}

# ============================================================
# 5. ATTACH POLICIES TO EC2 INSTANCE ROLE
# ============================================================

# SSM for secure shell access (no SSH keys needed)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch agent for metrics and logs
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom EC2 application policy
resource "aws_iam_role_policy_attachment" "ec2_app" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = aws_iam_policy.ec2_application.arn
}
