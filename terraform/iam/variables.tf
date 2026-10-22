# ============================================================
# variables.tf - IAM Module Variables
# ============================================================

# ── General ────────────────────────────────────────────────

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

# ── Trust Relationships ────────────────────────────────────

variable "trusted_role_arns" {
  description = "List of IAM ARNs allowed to assume the Terraform execution role"
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID for cross-account role assumption (security best practice)"
  type        = string
  sensitive   = true
}

variable "gitlab_project_path" {
  description = "GitLab project path for OIDC authentication (e.g., 'group/project')"
  type        = string
  default     = ""
}

# ── CI/CD User ─────────────────────────────────────────────

variable "create_cicd_user" {
  description = "Whether to create an IAM user for CI/CD (set false if using OIDC)"
  type        = bool
  default     = false
}

# ── Terraform State ────────────────────────────────────────

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "terraform_state_lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting secrets and state (optional)"
  type        = string
  default     = ""
}
