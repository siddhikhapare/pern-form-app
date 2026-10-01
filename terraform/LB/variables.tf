variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "private_app_subnet_ids" { type = list(string) }
variable "external_alb_sg_id" {}
variable "internal_alb_sg_id" {}
variable "app_port" {}
variable "web_health_check_path" {}
variable "app_health_check_path" {}
# variable "acm_certificate_arn" {
#   default = ""
# }