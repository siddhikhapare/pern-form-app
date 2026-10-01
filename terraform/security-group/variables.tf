# ============================================================
# variables.tf  —  Security Group Module Variables
# ============================================================

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "bastion_ingress_cidr" {
  description = "CIDR block allowed to SSH to Bastion"
  type        = string
}

variable "app_port" {
  description = "Application port for Node.js backend"
  type        = number
  default     = 5000
}


#vpc_id = "vpc-05b3010150caec1c7"
#vpc_id = "vpc-0dce8ad940985a617"