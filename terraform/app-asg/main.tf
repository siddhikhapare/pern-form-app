resource "aws_launch_template" "app" {
  name        = "${var.project_name}-${var.environment}-app-lt"
  description = "Launch template for App-tier (Node.js) instances"

  image_id      = var.app_ami_id
  instance_type = var.app_instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
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

  # DB credentials are injected here at launch time, once RDS exists —
  # not baked into the AMI. Paths match what the ami module clones to.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -ex

    APP_DIR="/home/ubuntu/pern-form-app/backend"

    cat > $APP_DIR/.env <<ENVEOF
    DB_HOST=${var.db_host}
    DB_PORT=5432
    DB_NAME=${var.db_name}
    DB_USER=${var.db_username}
    DB_PASSWORD=${var.db_password}
    NODE_ENV=production
    PORT=5000
    ENVEOF

    cat > $APP_DIR/ecosystem.config.js <<'ECOSYSTEM'
    module.exports = {
      apps: [{
        name: 'backend',
        script: './server.js',
        instances: 'max',
        exec_mode: 'cluster',
        autorestart: true,
        watch: false,
        max_memory_restart: '500M',
        env: {
          NODE_ENV: 'production',
          PORT: 5000
        },
        error_file: './logs/errors.log',
        out_file: './logs/out.log',
        log_file: './logs/appcombined.log',
        time: true
      }]
    };
    ECOSYSTEM

    cd $APP_DIR
    pm2 delete all || true
    pm2 start ecosystem.config.js
    pm2 save
    sudo env PATH=$PATH pm2 startup systemd -u ubuntu --hp /home/ubuntu
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app-instance"
      Tier        = "App"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-${var.environment}-app-volume"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-lt"
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-${var.environment}-app-asg"
  min_size            = var.app_asg_min_size
  max_size            = var.app_asg_max_size
  desired_capacity    = var.app_asg_desired_capacity
  vpc_zone_identifier = var.private_app_subnet_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [var.app_target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 180

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
    "GroupInServiceInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Tier"
    value               = "App"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "backend_cpu" {
  name                   = "${var.environment}-${var.project_name}-app-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Scale out App ASG when CPU is high"
  alarm_actions       = var.alarm_actions

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-cpu-high"
  }
}