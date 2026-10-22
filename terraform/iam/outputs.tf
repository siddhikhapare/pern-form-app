# ============================================================
# outputs.tf - IAM Module Outputs
# ============================================================

# ── Terraform Execution Role ───────────────────────────────

output "terraform_execution_role_arn" {
  description = "ARN of the Terraform execution role"
  value       = aws_iam_role.terraform_execution.arn
}

output "terraform_execution_role_name" {
  description = "Name of the Terraform execution role"
  value       = aws_iam_role.terraform_execution.name
}

# ── EC2 Instance Role ──────────────────────────────────────

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance role"
  value       = aws_iam_role.ec2_instance.arn
}

output "ec2_instance_role_name" {
  description = "Name of the EC2 instance role"
  value       = aws_iam_role.ec2_instance.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.arn
}

# ── CI/CD User (if created) ────────────────────────────────

output "cicd_user_arn" {
  description = "ARN of the CI/CD IAM user (if created)"
  value       = var.create_cicd_user ? aws_iam_user.cicd[0].arn : null
}

output "cicd_user_name" {
  description = "Name of the CI/CD IAM user (if created)"
  value       = var.create_cicd_user ? aws_iam_user.cicd[0].name : null
}

# ── Policy ARNs ────────────────────────────────────────────

output "policy_arns" {
  description = "Map of all custom policy ARNs"
  value = {
    vpc         = aws_iam_policy.terraform_vpc.arn
    ec2         = aws_iam_policy.terraform_ec2.arn
    alb         = aws_iam_policy.terraform_alb.arn
    asg         = aws_iam_policy.terraform_asg.arn
    rds         = aws_iam_policy.terraform_rds.arn
    cloudfront  = aws_iam_policy.terraform_cloudfront.arn
    route53     = aws_iam_policy.terraform_route53.arn
    acm         = aws_iam_policy.terraform_acm.arn
    monitoring  = aws_iam_policy.terraform_monitoring.arn
    iam         = aws_iam_policy.terraform_iam.arn
    state       = aws_iam_policy.terraform_state.arn
    ec2_app     = aws_iam_policy.ec2_application.arn
  }
}
