# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.subnets.private_subnet_ids
}

# output "database_subnet_ids" {
#   description = "List of database subnet IDs"
#   value       = module.subnets.database_subnet_ids
# }

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = module.subnets.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = module.subnets.private_subnet_cidrs
}

# output "database_subnet_cidrs" {
#   description = "List of database subnet CIDR blocks"
#   value       = module.subnets.database_subnet_cidrs
# }

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.subnets.availability_zones
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "The ID of the internet gateway"
  value       = module.internet_gateway.internet_gateway_id
}

output "internet_gateway_arn" {
  description = "The ARN of the internet gateway"
  value       = module.internet_gateway.internet_gateway_arn
}

# Route Tables Outputs
output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = module.route_tables.public_route_table_id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = module.route_tables.private_route_table_ids
}

# Security Groups Outputs

output "web_security_group_id" {
  description = "The ID of the web security group"
  value       = module.security_groups.web_security_group_id
}


# IAM Outputs
output "ec2_role_name" {
  description = "Name of the EC2 IAM role"
  value       = module.iam.ec2_role_name
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = module.iam.ec2_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.iam.ec2_instance_profile_name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = module.iam.ec2_instance_profile_arn
}

# EC2 Outputs
output "ec2_instance_ids" {
  description = "List of EC2 instance IDs"
  value       = module.ec2.instance_ids
}

output "ec2_instance_private_ips" {
  description = "List of EC2 instance private IP addresses"
  value       = module.ec2.instance_private_ips
}

output "ec2_instance_public_ips" {
  description = "List of EC2 instance public IP addresses"
  value       = module.ec2.instance_public_ips
} 