output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.main[*].id
}

output "instance_private_ips" {
  description = "List of EC2 instance private IP addresses"
  value       = aws_instance.main[*].private_ip
}

output "instance_public_ips" {
  description = "List of EC2 instance public IP addresses"
  value       = aws_instance.main[*].public_ip
}

output "ami_id" {
  description = "AMI ID used for instances (Ubuntu 24.04 LTS if no custom AMI specified)"
  value       = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_24.id
} 