# ============================================================
# EXTERNAL APPLICATION LOAD BALANCER
# Serves plain HTTP only — CloudFront is the sole TLS
# termination point in this architecture (origin_protocol_policy
# = "http-only" in the cdn module). This ALB never terminates
# TLS and therefore needs no ACM certificate at all.
# ============================================================

resource "aws_lb" "external" {
  name               = "${var.project_name}-${var.environment}-ext-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.external_alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-${var.environment}-ext-alb"
    Tier = "Web"
  }
}

resource "aws_lb_target_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.web_health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  deregistration_delay = 60

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-tg"
    Tier = "Web"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── External ALB — HTTP Listener ───────────────────────────
# CHANGED: forwards directly to the target group instead of
# redirecting to HTTPS. This ALB has no HTTPS listener at all —
# CloudFront handles the browser-facing TLS termination and
# connects to this ALB over plain HTTP (origin_protocol_policy
# = "http-only"). A redirect here would send CloudFront's
# origin requests to a port this ALB never listens on,
# producing a broken redirect loop / 502s for every visitor.
resource "aws_lb_listener" "external_http" {
  load_balancer_arn = aws_lb.external.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# REMOVED: aws_lb_listener "external_https" and its ACM cert
# dependency (var.acm_certificate_arn) — not needed. This ALB
# never terminates TLS. If you later switch the CDN's
# origin_protocol_policy back to "https-only", reintroduce this
# listener along with a regional ACM cert (same region as this
# ALB) covering the origin hostname CloudFront is configured
# to validate against.

# ============================================================
# INTERNAL APPLICATION LOAD BALANCER  (unchanged)
# ============================================================

resource "aws_lb" "internal" {
  name               = "${var.project_name}-${var.environment}-int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.private_app_subnet_ids

  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-${var.environment}-int-alb"
    Tier = "App"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.app_health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  deregistration_delay = 60

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-tg"
    Tier = "App"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

 
# private - ["subnet-0338e9a26d155ecd4", "subnet-05b5c92e4c16044b6"]
#public - ["subnet-07b5dc00689f0d695", "subnet-0810ecba16214f67d"]
#vpc-0dce8ad940985a617

#app_target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:470224090655:targetgroup/formapp-prod-app-tg/24dd3da765e181ad"
#external_alb_dns_name = "formapp-prod-ext-alb-1018504682.us-east-1.elb.amazonaws.com"
#internal_alb_arn = "arn:aws:elasticloadbalancing:us-east-1:470224090655:loadbalancer/app/formapp-prod-int-alb/a891349a02d39ae1"
#internal_alb_dns_name = "internal-formapp-prod-int-alb-1028028943.us-east-1.elb.amazonaws.com"
#web_target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:470224090655:targetgroup/formapp-prod-web-tg/da0101b63672902c"
