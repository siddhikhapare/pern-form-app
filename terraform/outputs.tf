# ============================================================
# outputs.tf  —  Root Module Outputs
# ============================================================

# ── VPC Outputs ────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of private app subnets"
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of private database subnets"
  value       = module.vpc.private_db_subnet_ids
}

# ── Bastion Host ───────────────────────────────────────────

output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_instance_id" {
  description = "Instance ID of the Bastion host"
  value       = module.bastion.bastion_instance_id
}

# ── ALB Outputs ────────────────────────────────────────────

output "external_alb_dns_name" {
  description = "DNS name of the external ALB"
  value       = module.alb.external_alb_dns_name
}

output "external_alb_zone_id" {
  description = "Zone ID of the external ALB"
  value       = module.alb.external_alb_zone_id
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = module.alb.internal_alb_dns_name
}

# ── RDS Outputs ────────────────────────────────────────────

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

# ── AMI Outputs ────────────────────────────────────────────

output "web_ami_id" {
  description = "AMI ID for Web tier"
  value       = module.ami.web_ami_id
}

output "app_ami_id" {
  description = "AMI ID for App tier"
  value       = module.ami.app_ami_id
}

# ── ASG Outputs ────────────────────────────────────────────

output "web_asg_name" {
  description = "Name of the Web tier Auto Scaling Group"
  value       = module.web_asg.asg_name
}

output "app_asg_name" {
  description = "Name of the App tier Auto Scaling Group"
  value       = module.app_asg.asg_name
}

# ── CloudFront Outputs ─────────────────────────────────────

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.cloudfront_domain_name
}

# ── Application URL ────────────────────────────────────────

output "application_url" {
  description = "URL to access the application"
  value       = "https://${var.domain_name}"
}
