########################################
# CloudFront Distribution
########################################
data "aws_cloudfront_cache_policy" "use_origin_cache_control_headers" {
  name = "UseOriginCacheControlHeaders"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} CDN"
  #default_root_object = "index.html"
  #aliases             = [var.domain_name, "app.${var.domain_name}"] #change here
  aliases = [var.domain_name] #main domain without subdomain
  #price_class         = "PriceClass_100"   # US, Canada, Europe

  # ── Origin: External ALB ───────────────────
  origin {
    # domain_name = aws_lb.external.dns_name
    # origin_id   = "external-alb"
    domain_name = var.alb_dns_name
    origin_id   = var.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_keepalive_timeout  = 5
      origin_read_timeout       = 30
    }

    # custom_origin_config {
    #   http_port              = 80
    #   https_port             = 443
    #   origin_protocol_policy = "https-only" not HTTP also want 
    #   origin_ssl_protocols   = ["TLSv1.2"]
    #   origin_keepalive_timeout  = 5
    #   origin_read_timeout       = 30
    # }

    #     custom_origin_config {
    #   http_port               = 80
    #   https_port                = 443
    #   origin_protocol_policy    = "http-only"
    #   origin_keepalive_timeout  = 5
    #   origin_read_timeout       = 30
    # }]

    connection_attempts = 3
    connection_timeout  = 10

    # custom_header {
    #   name  = "X-Custom-Header"
    #   value = "${var.project_name}-cf-origin"   # ALB can verify this header
    # }
  }

  # ── Default Cache Behaviour ────────────────
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    #target_origin_id       = "external-alb"
    target_origin_id       = var.origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Cache policy – CachingDisabled for dynamic content
    # cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"   # CachingDisabled managed policy
    # origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"   # AllViewerExceptHostHeader

    cache_policy_id          = data.aws_cloudfront_cache_policy.use_origin_cache_control_headers.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id

    # min_ttl     = 0
    # default_ttl = 0
    # max_ttl     = 0
  }

  

  # ── Static Assets – cache aggressively ─────
#   ordered_cache_behavior {
#     path_pattern           = "/static/*"
#     allowed_methods        = ["GET", "HEAD", "OPTIONS"]
#     cached_methods         = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id       = "external-alb"
#     viewer_protocol_policy = "redirect-to-https"
#     compress               = true

#     cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"   # CachingOptimized

#     min_ttl     = 0
#     default_ttl = 86400
#     max_ttl     = 31536000
#   }

  # ── Geo-Restriction ────────────────────────
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ── TLS Certificate ────────────────────────
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # ── Custom Error Pages (React SPA) ─────────
#   custom_error_response {
#     error_code            = 403
#     response_code         = 200
#     response_page_path    = "/index.html"
#     error_caching_min_ttl = 0
#   }

#   custom_error_response {
#     error_code            = 404
#     response_code         = 200
#     response_page_path    = "/index.html"
#     error_caching_min_ttl = 0
#   }

    # No WAF attached (matches "Use existing WAF configuration: No" in console)
  web_acl_id = null

  tags = { Name = "${var.project_name}-${var.environment}-cloudfront" }
}

########################################
# Route 53 – Hosted Zone (data source)
########################################
data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

########################################
# Route 53 Records  (app  → CloudFront)
########################################
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# resource "aws_route53_record" "www" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = aws_cloudfront_distribution.main.domain_name
#     zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
