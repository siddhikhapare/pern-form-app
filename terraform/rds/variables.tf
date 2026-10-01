variable "project_name" {}
variable "environment" {}
variable "private_db_subnet_ids" { type = list(string) }
variable "rds_sg_id" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" { sensitive = true }
variable "db_engine_version" {}
variable "db_instance_class" {}
variable "db_allocated_storage" {}
variable "db_max_allocated_storage" {}
variable "db_backup_retention_days" {}
variable "db_deletion_protection" {}