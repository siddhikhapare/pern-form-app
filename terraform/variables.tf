# ── General ─────────────────────────────────────────────────
variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

# ── VPC ──────────────────────────────────────────────────────
variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_db_subnet_cidrs" {
  type = list(string)
}

# ── Security Groups / Bastion ───────────────────────────────
variable "bastion_ingress_cidr" {
  type = string
}

variable "bastion_instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

# ── Shared App Networking ───────────────────────────────────
variable "app_port" {
  type    = number
  default = 5000
}

variable "web_health_check_path" {
  type    = string
  default = "/health"
}

variable "app_health_check_path" {
  type    = string
  default = "/health"
}

# ── ALB / TLS ────────────────────────────────────────────────
variable "acm_certificate_arn" {
  description = "ACM cert ARN for the external ALB HTTPS listener (regional, same region as ALB)"
  type        = string
  default     = ""
}

# ── Instance Types ───────────────────────────────────────────
variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

# ── Web ASG ──────────────────────────────────────────────────
variable "web_asg_min_size" {
  type    = number
  default = 1
}

variable "web_asg_max_size" {
  type    = number
  default = 3
}

variable "web_asg_desired_capacity" {
  type    = number
  default = 1
}

# ── App ASG ──────────────────────────────────────────────────
variable "app_asg_min_size" {
  type    = number
  default = 1
}

variable "app_asg_max_size" {
  type    = number
  default = 3
}

variable "app_asg_desired_capacity" {
  type    = number
  default = 1
}

# ── Alarms / Notifications ──────────────────────────────────
variable "alarm_actions" {
  description = "List of ARNs (e.g. SNS topics) to notify on CloudWatch alarm state changes"
  type        = list(string)
  default     = []
}

variable "alert_email" {
  description = "Email address subscribed to the Web ASG SNS notifications"
  type        = string
}

# ── RDS ──────────────────────────────────────────────────────
variable "db_name" {
  type    = string
  default = "formappdb"
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_engine_version" {
  type    = string
  default = "16"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "db_backup_retention_days" {
  type    = number
  default = 7
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

# ── CDN / Route53 ────────────────────────────────────────────
variable "domain_name" {
  type = string
}

variable "hosted_zone_name" {
  type = string
}

variable "cloudfront_acm_certificate_arn" {
  description = "ACM cert ARN for CloudFront — MUST be issued in us-east-1 regardless of your main region"
  type        = string
}