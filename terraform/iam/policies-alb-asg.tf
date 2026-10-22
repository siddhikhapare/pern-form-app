# ============================================================
# IAM Policies - ALB and Auto Scaling
# ============================================================

# ── ALB Policy ─────────────────────────────────────────────
resource "aws_iam_policy" "terraform_alb" {
  name        = "${var.project_name}-${var.environment}-terraform-alb-policy"
  description = "Terraform permissions for Application Load Balancer"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ELBFullAccess"
        Effect = "Allow"
        Action = [
          # Load Balancers
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:ModifyLoadBalancerAttributes",
          "elasticloadbalancing:SetSecurityGroups",
          "elasticloadbalancing:SetSubnets",
          "elasticloadbalancing:SetIpAddressType",
          
          # Target Groups
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:ModifyTargetGroup",
          "elasticloadbalancing:ModifyTargetGroupAttributes",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeTargetHealth",
          
          # Listeners
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:ModifyListener",
          
          # Rules
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:ModifyRule",
          "elasticloadbalancing:SetRulePriorities",
          
          # SSL Certificates
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates",
          "elasticloadbalancing:DescribeListenerCertificates",
          
          # Tags
          "elasticloadbalancing:AddTags",
          "elasticloadbalancing:RemoveTags",
          "elasticloadbalancing:DescribeTags",
          
          # Account Limits
          "elasticloadbalancing:DescribeAccountLimits",
          "elasticloadbalancing:DescribeSSLPolicies"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-alb-policy"
  }
}

# ── Auto Scaling Policy ────────────────────────────────────
resource "aws_iam_policy" "terraform_asg" {
  name        = "${var.project_name}-${var.environment}-terraform-asg-policy"
  description = "Terraform permissions for Auto Scaling Groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AutoScalingFullAccess"
        Effect = "Allow"
        Action = [
          # Auto Scaling Groups
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:AttachInstances",
          "autoscaling:DetachInstances",
          "autoscaling:AttachLoadBalancers",
          "autoscaling:DetachLoadBalancers",
          "autoscaling:AttachLoadBalancerTargetGroups",
          "autoscaling:DetachLoadBalancerTargetGroups",
          "autoscaling:DescribeLoadBalancers",
          "autoscaling:DescribeLoadBalancerTargetGroups",
          
          # Scaling Policies
          "autoscaling:PutScalingPolicy",
          "autoscaling:DeletePolicy",
          "autoscaling:DescribePolicies",
          "autoscaling:ExecutePolicy",
          
          # Scheduled Actions
          "autoscaling:PutScheduledUpdateGroupAction",
          "autoscaling:DeleteScheduledAction",
          "autoscaling:DescribeScheduledActions",
          
          # Lifecycle Hooks
          "autoscaling:PutLifecycleHook",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:RecordLifecycleActionHeartbeat",
          
          # Notifications
          "autoscaling:PutNotificationConfiguration",
          "autoscaling:DeleteNotificationConfiguration",
          "autoscaling:DescribeNotificationConfigurations",
          
          # Instance Refresh
          "autoscaling:StartInstanceRefresh",
          "autoscaling:CancelInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes",
          
          # Warm Pools
          "autoscaling:PutWarmPool",
          "autoscaling:DeleteWarmPool",
          "autoscaling:DescribeWarmPool",
          
          # Tags
          "autoscaling:CreateOrUpdateTags",
          "autoscaling:DeleteTags",
          "autoscaling:DescribeTags",
          
          # Other
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeScalingProcessTypes",
          "autoscaling:DescribeTerminationPolicyTypes",
          "autoscaling:DescribeAccountLimits",
          "autoscaling:DescribeAdjustmentTypes",
          "autoscaling:DescribeMetricCollectionTypes",
          "autoscaling:EnableMetricsCollection",
          "autoscaling:DisableMetricsCollection",
          "autoscaling:SuspendProcesses",
          "autoscaling:ResumeProcesses",
          "autoscaling:SetInstanceProtection",
          "autoscaling:SetInstanceHealth"
        ]
        Resource = "*"
      },
      {
        Sid    = "ASGServiceLinkedRole"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "autoscaling.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-asg-policy"
  }
}
