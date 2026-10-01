variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name – used as a prefix for every resource"
  type        = string
  default     = "formapp"
}

variable "environment" {
  description = "Environment label (dev / staging / prod)"
  type        = string
  default     = "prod"
}
# ── Networking ────────────────────────────────────────────
variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnets – one per AZ (Web Tier)"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "Private subnets for App Tier – one per AZ"
  type        = list(string)
  default     = ["172.16.3.0/24", "172.16.4.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "Private subnets for DB Tier – one per AZ"
  type        = list(string)
  default     = ["172.16.5.0/24", "172.16.6.0/24"]
}
