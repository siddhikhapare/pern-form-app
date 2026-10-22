# ============================================================
# IAM Policies - RDS
# ============================================================

resource "aws_iam_policy" "terraform_rds" {
  name        = "${var.project_name}-${var.environment}-terraform-rds-policy"
  description = "Terraform permissions for RDS PostgreSQL"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RDSFullAccess"
        Effect = "Allow"
        Action = [
          # DB Instances
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:RebootDBInstance",
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          "rds:PromoteReadReplica",
          "rds:CreateDBInstanceReadReplica",
          
          # DB Subnet Groups
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:DescribeDBSubnetGroups",
          "rds:ModifyDBSubnetGroup",
          
          # DB Parameter Groups
          "rds:CreateDBParameterGroup",
          "rds:DeleteDBParameterGroup",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBParameters",
          "rds:ModifyDBParameterGroup",
          "rds:ResetDBParameterGroup",
          
          # DB Option Groups
          "rds:CreateOptionGroup",
          "rds:DeleteOptionGroup",
          "rds:DescribeOptionGroups",
          "rds:ModifyOptionGroup",
          "rds:DescribeOptionGroupOptions",
          
          # Snapshots
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:CopyDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBInstanceToPointInTime",
          
          # Automated Backups
          "rds:DescribeDBInstanceAutomatedBackups",
          "rds:DeleteDBInstanceAutomatedBackup",
          
          # Event Subscriptions
          "rds:CreateEventSubscription",
          "rds:DeleteEventSubscription",
          "rds:DescribeEventSubscriptions",
          "rds:ModifyEventSubscription",
          "rds:DescribeEvents",
          "rds:DescribeEventCategories",
          
          # Logs
          "rds:DescribeDBLogFiles",
          "rds:DownloadDBLogFilePortion",
          
          # Engine Versions
          "rds:DescribeDBEngineVersions",
          "rds:DescribeOrderableDBInstanceOptions",
          
          # Certificates
          "rds:DescribeCertificates",
          
          # Tags
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource",
          "rds:ListTagsForResource",
          
          # Account Attributes
          "rds:DescribeAccountAttributes",
          "rds:DescribeSourceRegions",
          
          # Enhanced Monitoring
          "rds:DescribeValidDBInstanceModifications",
          
          # Performance Insights
          "pi:GetResourceMetrics",
          "pi:DescribeDimensionKeys",
          "pi:GetDimensionKeyDetails"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSEnhancedMonitoringRole"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "rds.amazonaws.com"
          }
        }
      },
      {
        Sid    = "RDSPassMonitoringRole"
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = "arn:aws:iam::${local.account_id}:role/${var.project_name}-${var.environment}-rds-monitoring-role"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "monitoring.rds.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-terraform-rds-policy"
  }
}
