# ============================================================
# outputs.tf  —  Security Group Module Outputs
# ============================================================

output "bastion_sg_id" {
  description = "Security Group ID for Bastion host"
  value       = aws_security_group.bastion.id
}

output "external_alb_sg_id" {
  description = "Security Group ID for External ALB"
  value       = aws_security_group.external_alb.id
}

output "web_sg_id" {
  description = "Security Group ID for Web tier"
  value       = aws_security_group.web.id
}

output "internal_alb_sg_id" {
  description = "Security Group ID for Internal ALB"
  value       = aws_security_group.internal_alb.id
}

output "app_sg_id" {
  description = "Security Group ID for App tier"
  value       = aws_security_group.app.id
}

output "rds_sg_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}
