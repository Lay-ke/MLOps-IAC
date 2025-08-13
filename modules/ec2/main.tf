# Basic EC2 Module
# This module creates EC2 instances with basic configurations
locals {
  parent_dir = dirname(path.cwd)
}

# Data source for latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-2025*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instances
resource "aws_instance" "main" {
  count = var.instance_count

  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_24.id
  instance_type = var.instance_type
  key_name      = var.key_name

  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip

  iam_instance_profile = var.iam_instance_profile_name

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.delete_root_volume_on_termination
    encrypted             = var.encrypt_root_volume
  }

  user_data = base64gzip(file("${local.parent_dir}/MlOps-IAC/scripts/kubeadm_setup.sh"))

  tags = merge(
    {
      Name = "${var.name_prefix}-${count.index + 1}"
      Type = var.instance_type
    },
    var.tags
  )
} 