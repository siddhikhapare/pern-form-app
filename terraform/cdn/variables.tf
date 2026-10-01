variable "project_name" {
  description = "Name of the project, used for tagging and naming resources"
  type        = string
  default     = "formapp"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "demo"
}

variable "domain_name" {
  description = "Fully qualified domain name served by CloudFront (e.g. demo.siddhikapphub.org)"
  type        = string
  default     = "app.siddhikapphub.org"
  #default     = "demo.siddhikapphub.org"
}

variable "hosted_zone_name" {
  description = "Route 53 hosted zone name that the domain_name belongs to (must end with a trailing dot, e.g. siddhikapphub.org.)"
  type        = string
  default     = "app.siddhikapphub.org"
}

variable "alb_dns_name" {
  description = "DNS name of the existing Application/Elastic Load Balancer used as the CloudFront origin (e.g. Web-tier-lb-1055990391.ap-south-1.elb.amazonaws.com)"
  type        = string
}

variable "origin_id" {
  description = "Identifier used internally by CloudFront to reference the origin"
  type        = string
  default     = "elb-origin"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate (must be issued in us-east-1) covering the domain_name"
  type        = string
}
