# ============================================================
# IAM Policies - CloudFront and Route 53
# ============================================================

# ── CloudFront Policy ──────────────────────────────────────
resource "aws_iam_policy" "terraform_cloudfront" {
  name        = "${var.project_name}-${var.environment}-terraform-cloudfront-policy"
  description = "Terraform permissions for CloudFront CDN"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontFullAccess"
        Effect = "Allow"
        Action = [
          # Distributions
          "cloudfront:CreateDistribution",
          "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution",
          "cloudfront:ListDistributions",
          
          # Cache Policies
          "cloudfront:CreateCachePolicy",
          "cloudfront:DeleteCachePolicy",
          "cloudfront:GetCachePolicy",
          "cloudfront:GetCachePolicyConfig",
          "cloudfront:UpdateCachePolicy",
          "cloudfront:ListCachePolicies",
          
          # Origin Request Policies
          "cloudfront:CreateOriginRequestPolicy",
          "cloudfront:DeleteOriginRequestPolicy",
          "cloudfront:GetOriginRequestPolicy",
          "cloudfront:GetOriginRequestPolicyConfig",
          "cloudfront:UpdateOriginRequestPolicy",
          "cloudfront:ListOriginRequestPolicies",
          
          # Response Headers Policies
          "cloudfront:CreateResponseHeadersPolicy",
          "cloudfront:DeleteResponseHeadersPolicy",
          "cloudfront:GetResponseHeadersPolicy",
          "cloudfront:GetResponseHeadersPolicyConfig",
          "cloudfront:UpdateResponseHeadersPolicy",
          "cloudfront:ListResponseHeadersPolicies",
          
          # Origin Access Control
          "cloudfront:CreateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:GetOriginAccessControlConfig",
          "cloudfront:UpdateOriginAccessControl",
          "cloudfront:ListOriginAccessControls",
          
          # Invalidations
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          
          # Functions
          "cloudfront:CreateFunction",
          "cloudfront:DeleteFunction",
          "cloudfront:DescribeFunction",
          "cloudfront:GetFunction",
          "cloudfront:UpdateFunction",
          "cloudfront:PublishFunction",
          "cloudfront:ListFunctions",
          "cloudfront:TestFunction",
          
          # Tags
          "cloudfront:TagResource",
          "cloudfront:UntagResource",
          "cloudfront:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-cloudfront-policy"
  }
}

# ── Route 53 Policy ────────────────────────────────────────
resource "aws_iam_policy" "terraform_route53" {
  name        = "${var.project_name}-${var.environment}-terraform-route53-policy"
  description = "Terraform permissions for Route 53 DNS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Route53HostedZones"
        Effect = "Allow"
        Action = [
          # Hosted Zones
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:GetHostedZone",
          "route53:GetHostedZoneCount",
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
          "route53:UpdateHostedZoneComment",
          
          # Record Sets
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListResourceRecordSets",
          
          # Health Checks
          "route53:CreateHealthCheck",
          "route53:DeleteHealthCheck",
          "route53:GetHealthCheck",
          "route53:GetHealthCheckCount",
          "route53:GetHealthCheckStatus",
          "route53:ListHealthChecks",
          "route53:UpdateHealthCheck",
          
          # Tags
          "route53:ChangeTagsForResource",
          "route53:ListTagsForResource",
          "route53:ListTagsForResources",
          
          # Reusable Delegation Sets
          "route53:CreateReusableDelegationSet",
          "route53:DeleteReusableDelegationSet",
          "route53:GetReusableDelegationSet",
          "route53:ListReusableDelegationSets",
          
          # Query Logging
          "route53:CreateQueryLoggingConfig",
          "route53:DeleteQueryLoggingConfig",
          "route53:GetQueryLoggingConfig",
          "route53:ListQueryLoggingConfigs",
          
          # Traffic Policies
          "route53:CreateTrafficPolicy",
          "route53:CreateTrafficPolicyInstance",
          "route53:CreateTrafficPolicyVersion",
          "route53:DeleteTrafficPolicy",
          "route53:DeleteTrafficPolicyInstance",
          "route53:GetTrafficPolicy",
          "route53:GetTrafficPolicyInstance",
          "route53:ListTrafficPolicies",
          "route53:ListTrafficPolicyInstances",
          "route53:ListTrafficPolicyVersions",
          "route53:UpdateTrafficPolicyInstance",
          
          # DNSSEC
          "route53:GetDNSSEC",
          "route53:EnableHostedZoneDNSSEC",
          "route53:DisableHostedZoneDNSSEC"
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53DomainsReadOnly"
        Effect = "Allow"
        Action = [
          "route53domains:GetDomainDetail",
          "route53domains:ListDomains",
          "route53domains:ListOperations"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-route53-policy"
  }
}

# ── ACM Policy ─────────────────────────────────────────────
resource "aws_iam_policy" "terraform_acm" {
  name        = "${var.project_name}-${var.environment}-terraform-acm-policy"
  description = "Terraform permissions for ACM certificates"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ACMFullAccess"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DeleteCertificate",
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "acm:AddTagsToCertificate",
          "acm:RemoveTagsFromCertificate",
          "acm:RenewCertificate",
          "acm:ResendValidationEmail",
          "acm:UpdateCertificateOptions",
          "acm:ExportCertificate",
          "acm:ImportCertificate"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-acm-policy"
  }
}
