# ============================================================
# variables.tf  —  Bastion Host Module Variables
# ============================================================

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type for Bastion host"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet for Bastion host"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security Group ID for Bastion host"
  type        = string
}

#bastion_instance_id = "i-0fb8616d1ccdf2c08"
#bastion_private_ip = "172.16.1.179"
#bastion_public_ip = "3.235.196.50"