variable "project_name" {}
variable "environment" {}
variable "key_name" {}
variable "app_instance_type" {}
variable "app_ami_id" {}
variable "ec2_instance_profile_name" {}
variable "private_app_subnet_ids" { type = list(string) }
variable "app_sg_id" {}
variable "app_target_group_arn" {}
variable "app_asg_min_size" {}
variable "app_asg_max_size" {}
variable "app_asg_desired_capacity" {}
variable "db_host" {}
variable "db_name" {}
variable "db_username" {}
variable "db_password" { sensitive = true }
variable "alarm_actions" { 
    type = list(string) 
    default = []
}