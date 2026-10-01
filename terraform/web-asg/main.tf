resource "aws_launch_template" "web" {
  name        = "${var.project_name}-${var.environment}-web-lt"
  description = "Launch template for Web-tier (Nginx + React) instances"

  image_id      = var.web_ami_id
  instance_type = var.web_instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.web_sg_id]
    delete_on_termination       = true
  }

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      delete_on_termination = true
      encrypted              = true
    }
  }

  monitoring {
    enabled = true
  }

  # The AMI already bakes in the correct Internal ALB DNS at build time
  # (see ami module), so no runtime sed/placeholder substitution is
  # needed here. Left as a no-op restart in case of drift.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -ex
    systemctl restart nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-web-instance"
      Tier        = "Web"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-${var.environment}-web-volume"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-lt"
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  min_size            = var.web_asg_min_size
  max_size            = var.web_asg_max_size
  desired_capacity    = var.web_asg_desired_capacity
  vpc_zone_identifier = var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  target_group_arns = [var.web_target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
    triggers = ["launch_template"]
  }

  termination_policies = ["OldestInstance"]

  enabled_metrics = [
    "GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity",
    "GroupInServiceCapacity", "GroupPendingCapacity",
    "GroupTerminatingCapacity", "GroupTotalCapacity",
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Tier"
    value               = "Web"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web_cpu" {
  name                   = "${var.environment}-${var.project_name}-web-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-web-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors frontend EC2 CPU utilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_actions = var.alarm_actions

  tags = {
    Name = "${var.project_name}-${var.environment}-web-cpu-high"
  }
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-web-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 15
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 49
  alarm_description   = "Scale in Web ASG when CPU is low"
  alarm_actions       = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-cpu-low"
  }
}

resource "aws_cloudwatch_metric_alarm" "web_unhealthy" {
  alarm_name          = "${var.environment}-${var.project_name}-web-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when frontend instances are unhealthy"
  alarm_actions       = var.alarm_actions

  dimensions = {
    TargetGroup = split(":", var.web_target_group_arn)[5]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-unhealthy"
  }
}

resource "aws_sns_topic" "web_asg_sns" {
  name = "${var.project_name}-${var.environment}-web-server-sns"

  tags = {
    Name        = "${var.project_name}-${var.environment}-web-server-sns"
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "web_asg_email" {
  topic_arn = aws_sns_topic.web_asg_sns.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_autoscaling_notification" "web_asg_notifications" {
  group_names = [aws_autoscaling_group.web.name]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
    "autoscaling:TEST_NOTIFICATION",
  ]

  topic_arn = aws_sns_topic.web_asg_sns.arn
}