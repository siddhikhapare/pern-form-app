resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "postgresql" {
  name        = "${var.project_name}-${var.environment}-pg-params"
  family      = "postgres16"
  description = "Custom PostgreSQL 16 parameter group"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "0"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"   # Log queries slower than 1 second
  }

  parameter {
    name         = "log_lock_waits"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_temp_files"
    value        = "1024"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_autovacuum_min_duration"
    value        = "1000"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_statement"
    value        = "ddl"
    apply_method = "immediate"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-pg-params"
  }
}

resource "aws_db_instance" "postgresql" {
  identifier     = "${var.project_name}-${var.environment}-postgresql"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true   # fixed: was false, inconsistent with rest of infra

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  multi_az                = true
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.rds_sg_id]
  parameter_group_name    = aws_db_parameter_group.postgresql.name
  publicly_accessible     = false

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period  = var.db_backup_retention_days
  backup_window             = "03:00-04:00"
  maintenance_window        = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot     = true
  delete_automated_backups  = false

  deletion_protection       = var.db_deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-postgresql-final-snap"

  iam_database_authentication_enabled = false
  auto_minor_version_upgrade          = false

  tags = {
    Name = "${var.project_name}-${var.environment}-postgresql"
    Tier = "Database"
  }
}