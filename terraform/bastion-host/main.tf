# ============================================================
# Bastion Host Module
# ============================================================

# Data source — latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Keep metadata service limited to IMDSv2 for security
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    delete_on_termination = true
    encrypted             = true
  }

  # user_data = base64encode(<<-EOF
  #   #!/bin/bash
  #   set -ex
  #   apt-get update -y
  #   apt-get install -y postgresql-client-16
  #   echo "Bastion host setup complete" > /tmp/userdata_done.txt
  # EOF
  # )

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion"
    Role = "Bastion"
  }
}
