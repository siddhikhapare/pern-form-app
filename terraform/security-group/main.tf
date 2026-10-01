# ============================================================
# Security Groups Module
# ============================================================

# ── Bastion Host SG ───────────────────────────────────────
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Allow SSH from a trusted CIDR to the Bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_ingress_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
  }
}

# ── External ALB SG ───────────────────────────────────────
resource "aws_security_group" "external_alb" {
  name        = "${var.project_name}-${var.environment}-ext-alb-sg"
  description = "Allow HTTP/HTTPS from the internet to the External ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   description = "HTTPS from internet"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ext-alb-sg"
  }
}

# ── Web Tier SG ───────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Allow traffic from External ALB and SSH from Bastion to Web instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from External ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.external_alb.id]
  }

  # ingress {
  #   description     = "HTTPS from External ALB"
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   security_groups = [aws_security_group.external_alb.id]
  # }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }
}

# ── Internal ALB SG ───────────────────────────────────────
resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-${var.environment}-int-alb-sg"
  description = "Allow traffic from Web tier to Internal ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "API traffic from Web instances (Nginx proxy)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-int-alb-sg"
  }
}

# ── App Tier SG ───────────────────────────────────────────
resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Allow Node.js port from Internal ALB and SSH from Bastion"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Node.js port from Internal ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }
}

# ── RDS SG ────────────────────────────────────────────────
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow PostgreSQL from App tier and Bastion only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from App tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  ingress {
    description     = "PostgreSQL from Bastion (admin/migrations)"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}
