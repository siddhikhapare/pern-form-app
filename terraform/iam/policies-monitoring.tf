# ============================================================
# IAM Policies - CloudWatch, SNS, and Monitoring
# ============================================================

resource "aws_iam_policy" "terraform_monitoring" {
  name        = "${var.project_name}-${var.environment}-terraform-monitoring-policy"
  description = "Terraform permissions for CloudWatch, SNS, and monitoring"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchAlarms"
        Effect = "Allow"
        Action = [
          # Alarms
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:EnableAlarmActions",
          "cloudwatch:DisableAlarmActions",
          "cloudwatch:SetAlarmState",
          
          # Metrics
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutMetricData",
          
          # Dashboards
          "cloudwatch:PutDashboard",
          "cloudwatch:DeleteDashboards",
          "cloudwatch:GetDashboard",
          "cloudwatch:ListDashboards",
          
          # Composite Alarms
          "cloudwatch:PutCompositeAlarm",
          
          # Anomaly Detection
          "cloudwatch:PutAnomalyDetector",
          "cloudwatch:DeleteAnomalyDetector",
          "cloudwatch:DescribeAnomalyDetectors",
          
          # Insights
          "cloudwatch:GetInsightRuleReport",
          "cloudwatch:PutInsightRule",
          "cloudwatch:DeleteInsightRules",
          "cloudwatch:DescribeInsightRules",
          
          # Tags
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource",
          "cloudwatch:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          # Log Groups
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          
          # Log Streams
          "logs:CreateLogStream",
          "logs:DeleteLogStream",
          "logs:DescribeLogStreams",
          
          # Log Events
          "logs:GetLogEvents",
          "logs:PutLogEvents",
          "logs:FilterLogEvents",
          
          # Metric Filters
          "logs:PutMetricFilter",
          "logs:DeleteMetricFilter",
          "logs:DescribeMetricFilters",
          
          # Subscription Filters
          "logs:PutSubscriptionFilter",
          "logs:DeleteSubscriptionFilter",
          "logs:DescribeSubscriptionFilters",
          
          # Resource Policies
          "logs:PutResourcePolicy",
          "logs:DeleteResourcePolicy",
          "logs:DescribeResourcePolicies",
          
          # Queries
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:DescribeQueries",
          
          # Tags
          "logs:TagLogGroup",
          "logs:UntagLogGroup",
          "logs:ListTagsLogGroup",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSFullAccess"
        Effect = "Allow"
        Action = [
          # Topics
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:ListTopics",
          
          # Subscriptions
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ConfirmSubscription",
          "sns:GetSubscriptionAttributes",
          "sns:SetSubscriptionAttributes",
          "sns:ListSubscriptions",
          "sns:ListSubscriptionsByTopic",
          
          # Publishing
          "sns:Publish",
          
          # Tags
          "sns:TagResource",
          "sns:UntagResource",
          "sns:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "EventBridge"
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:DeleteRule",
          "events:DescribeRule",
          "events:EnableRule",
          "events:DisableRule",
          "events:ListRules",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:ListTargetsByRule",
          "events:TagResource",
          "events:UntagResource",
          "events:ListTagsForResource"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-monitoring-policy"
  }
}
