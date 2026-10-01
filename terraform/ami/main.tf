data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.project_name}-${var.environment}-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-instance-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

# ============================================================
# WEB TIER BASE INSTANCE (Nginx + React)
# ============================================================
resource "aws_instance" "web_base" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.web_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.web_sg_id]
  key_name               = var.key_name
  iam_instance_profile    = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    encrypted              = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -ex

    sudo apt update -y
    sudo apt install -y nginx git

    sudo snap install node --classic --channel=20/stable
    node --version
    npm --version

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm --version

    mkdir -p /home/ubuntu/pern-form-app
    cd /home/ubuntu
    git clone https://github.com/siddhikhapare/pern-form-app.git

    cd /home/ubuntu/pern-form-app/frontend
    npm install

    cat > .env.production <<ENV
    NEXT_PUBLIC_API_URL=https://siddhikapphub.org/api
    ENV

    npm run build

    mkdir -p /var/www/pern-form-app
    cp -r /home/ubuntu/pern-form-app/frontend/out/* /var/www/pern-form-app/
    chown -R www-data:www-data /var/www/pern-form-app
    chmod -R 755 /var/www/pern-form-app

    INTERNAL_ALB_DNS="${var.internal_alb_dns}"

    cat > /etc/nginx/sites-available/default <<NGINX
    server {
        listen 80;
        server_name domain-name;

        root /home/ubuntu/pern-form-app/frontend/out;

        location /health {
            default_type text/plain;
            return 200 "healthy";
        }

        location /_next/static/ {
            expires 365d;
            access_log off;
            add_header Cache-Control "public, max-age=31536000, immutable";
        }

        location ~* \\.(jpg|jpeg|png|gif|ico|svg|webp|woff|woff2|ttf|eot)$ {
            expires 365d;
            access_log off;
            add_header Cache-Control "public, max-age=31536000, immutable";
        }

        location ~* \\.(css|js)$ {
            expires 365d;
            access_log off;
            add_header Cache-Control "public, max-age=31536000, immutable";
        }

        location /api/ {
            proxy_pass http://$INTERNAL_ALB_DNS/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location / {
            index index.html;
            try_files \$uri \$uri.html \$uri/ /index.html;
        }
    }
    NGINX

    sudo apt install -y stress-ng

    nginx -t
    systemctl enable nginx
    systemctl restart nginx

    echo "Web base instance configuration complete" > /tmp/userdata_done.txt
  EOF
  )

  tags = {
    Name = "${var.project_name}-${var.environment}-web-base-instance"
    Role = "WebBaseForAMI"
  }
}

resource "aws_ami_from_instance" "web" {
  name                = "${var.project_name}-${var.environment}-web-ami"
  source_instance_id  = aws_instance.web_base.id

  tags = {
    Name      = "${var.project_name}-${var.environment}-web-ami"
    Tier      = "Web"
    BaseEc2Id = aws_instance.web_base.id
  }

  depends_on = [aws_instance.web_base]
}

# ============================================================
# APP TIER BASE INSTANCE (Node.js) — no DB config baked in
# ============================================================
resource "aws_instance" "app_base" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.app_instance_type
  subnet_id              = var.private_app_subnet_id
  vpc_security_group_ids = [var.app_sg_id]
  key_name               = var.key_name
  iam_instance_profile    = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted              = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -ex

    sudo apt update -y
    sudo apt install -y git postgresql-client-16

    sudo snap install node --classic --channel=20/stable
    node --version
    npm --version

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm --version

    cd /home/ubuntu
    git clone https://github.com/siddhikhapare/pern-form-app.git
    cd /home/ubuntu/pern-form-app/backend
    npm install

    sudo npm install -g pm2

    # NOTE: .env and ecosystem.config.js are intentionally NOT created
    # here — real DB credentials/host get injected by the app_asg
    # module's launch-template user_data, after RDS exists.

    echo "App base instance configuration complete" > /tmp/userdata_app_done.txt
  EOF
  )

  tags = {
    Name = "${var.project_name}-${var.environment}-app-base-instance"
    Role = "AppBaseForAMI"
  }
}

resource "aws_ami_from_instance" "app" {
  name                = "${var.project_name}-${var.environment}-app-ami"
  source_instance_id  = aws_instance.app_base.id

  tags = {
    Name      = "${var.project_name}-${var.environment}-app-ami"
    Tier      = "App"
    BaseEc2Id = aws_instance.app_base.id
  }

  depends_on = [aws_instance.app_base]
}