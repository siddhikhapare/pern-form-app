variable "project_name" {}
variable "environment" {}
variable "key_name" {}
variable "web_instance_type" {type = string}
variable "web_ami_id" {}
variable "ec2_instance_profile_name" {}
variable "public_subnet_ids" { type = list(string) }
variable "web_sg_id" {}
variable "web_target_group_arn" {}
# variable "internal_alb_dns" {}
variable "web_asg_min_size" {}
variable "web_asg_max_size" {}
variable "web_asg_desired_capacity" {}
variable "alarm_actions" {
    type = list(string)
    default = []
}
variable "alert_email" {}