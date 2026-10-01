terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.40"
    }
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# VPC Module
# ============================================================
module "vpc" {
  source = "./vpc"

  project_name             = var.project_name
  environment              = var.environment
  aws_region               = var.aws_region
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

# ============================================================
# Security Groups Module
# ============================================================
module "security_group" {
  source = "./security-group"

  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  vpc_cidr             = var.vpc_cidr
  bastion_ingress_cidr = var.bastion_ingress_cidr
  app_port             = var.app_port
}

# ============================================================
# Bastion Host Module
# ============================================================
module "bastion" {
  source = "./bastion-host"

  project_name          = var.project_name
  environment           = var.environment
  bastion_instance_type = var.bastion_instance_type
  key_name              = var.key_name
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  bastion_sg_id         = module.security_group.bastion_sg_id
}

# ============================================================
# ALB Module
# ============================================================
module "alb" {
  source = "./alb"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  external_alb_sg_id     = module.security_group.external_alb_sg_id
  internal_alb_sg_id     = module.security_group.internal_alb_sg_id
  app_port               = var.app_port
  web_health_check_path  = var.web_health_check_path
  app_health_check_path  = var.app_health_check_path
  #acm_certificate_arn     = var.acm_certificate_arn no need of HTTPS here , we add in cdn to forward
}

# ============================================================
# RDS Module
# (moved above ami/web_asg/app_asg since ami no longer needs it,
#  but app_asg still does — ordering here is just readability;
#  Terraform resolves the real order from references either way)
# ============================================================
module "rds" {
  source = "./rds"

  project_name             = var.project_name
  environment              = var.environment
  private_db_subnet_ids    = module.vpc.private_db_subnet_ids
  rds_sg_id                = module.security_group.rds_sg_id
  db_name                  = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password
  db_engine_version        = var.db_engine_version
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_backup_retention_days = var.db_backup_retention_days
  db_deletion_protection   = var.db_deletion_protection
}

# ============================================================
# AMI Module (Base Instances + Custom AMIs)
# NOTE: db_host/db_name/db_username/db_password removed —
# the ami module no longer bakes DB config into the AMI
# (RDS doesn't exist yet at this point in the graph). DB
# credentials are now injected at launch-template time in
# the app_asg module instead.
# ============================================================
module "ami" {
  source = "./ami"

  project_name          = var.project_name
  environment           = var.environment
  key_name              = var.key_name
  web_instance_type     = var.web_instance_type
  app_instance_type     = var.app_instance_type
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  private_app_subnet_id = module.vpc.private_app_subnet_ids[0]
  web_sg_id             = module.security_group.web_sg_id
  app_sg_id             = module.security_group.app_sg_id
  internal_alb_dns      = module.alb.internal_alb_dns_name

  depends_on = [module.vpc, module.alb]
}

# ============================================================
# Web ASG Module
# NOTE: internal_alb_dns removed from this call — the web
# launch template no longer needs it at runtime since the
# AMI already bakes the correct nginx proxy_pass target in
# at build time.
# ============================================================
module "web_asg" {
  source = "./web-asg"

  project_name = var.project_name
  environment  = var.environment
  key_name     = var.key_name
  # internal_alb_dns           = module.alb.internal_alb_dns_name
  web_instance_type         = var.web_instance_type
  web_ami_id                = module.ami.web_ami_id
  ec2_instance_profile_name = module.ami.ec2_instance_profile_name
  public_subnet_ids         = module.vpc.public_subnet_ids
  web_sg_id                 = module.security_group.web_sg_id
  web_target_group_arn      = module.alb.web_target_group_arn
  web_asg_min_size          = var.web_asg_min_size
  web_asg_max_size          = var.web_asg_max_size
  web_asg_desired_capacity  = var.web_asg_desired_capacity
  alarm_actions             = var.alarm_actions
  alert_email               = var.alert_email

  depends_on = [module.alb, module.ami]
}

# Unexpected attribute: An attribute named "internal_alb_dns" is not expected hereTerraform

# internal_alb_dns required, any type

# ============================================================
# App ASG Module
# (this is where db_host/db_name/db_username/db_password
# now actually belong — RDS exists by the time this runs)
# ============================================================
module "app_asg" {
  source = "./app-asg"

  project_name              = var.project_name
  environment               = var.environment
  key_name                  = var.key_name
  app_instance_type         = var.app_instance_type
  app_ami_id                = module.ami.app_ami_id
  ec2_instance_profile_name = module.ami.ec2_instance_profile_name
  private_app_subnet_ids    = module.vpc.private_app_subnet_ids
  app_sg_id                 = module.security_group.app_sg_id
  app_target_group_arn      = module.alb.app_target_group_arn
  app_asg_min_size          = var.app_asg_min_size
  app_asg_max_size          = var.app_asg_max_size
  app_asg_desired_capacity  = var.app_asg_desired_capacity
  db_host                   = module.rds.db_endpoint
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  alarm_actions             = var.alarm_actions

  depends_on = [module.alb, module.ami, module.rds]
}

# ============================================================
# CDN Module (CloudFront + Route 53)
# ============================================================
module "cdn" {
  source = "./cdn"

  project_name        = var.project_name
  environment         = var.environment
  domain_name         = var.domain_name
  hosted_zone_name    = var.hosted_zone_name
  alb_dns_name        = module.alb.external_alb_dns_name
  origin_id           = "external-alb"
  acm_certificate_arn = var.cloudfront_acm_certificate_arn

  depends_on = [module.alb]
}