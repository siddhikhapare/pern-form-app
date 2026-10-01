variable "project_name" {}
variable "environment" {}
variable "key_name" {}
variable "web_instance_type" {}
variable "app_instance_type" {}
variable "public_subnet_id" {}
variable "private_app_subnet_id" {}
variable "web_sg_id" {}
variable "app_sg_id" {}
variable "internal_alb_dns" {}
# NOTE: db_host/db_name/db_username/db_password are intentionally NOT
# used to bake the AMI (RDS doesn't exist yet at this point in the
# dependency graph). They're injected later at launch-template time
# in the app_asg module instead.