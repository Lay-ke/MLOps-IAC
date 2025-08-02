# AWS Region
variable "aws_region" {
  description = "AWS region"
  type        = string
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for VPC"
  type        = string
  default     = "main-vpc"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

# Subnet Configuration
variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
  validation {
    condition     = var.az_count >= 1 && var.az_count <= 6
    error_message = "AZ count must be between 1 and 6."
  }
}

variable "subnet_bits" {
  description = "Number of bits to add to VPC CIDR for subnet CIDR"
  type        = number
  default     = 8
  validation {
    condition     = var.subnet_bits >= 4 && var.subnet_bits <= 16
    error_message = "Subnet bits must be between 4 and 16."
  }
}

variable "subnet_name_prefix" {
  description = "Prefix for subnet names"
  type        = string
  default     = "subnet"
}

variable "create_database_subnets" {
  description = "Whether to create database subnets"
  type        = bool
  default     = false
}

# Internet Gateway Configuration
variable "igw_name" {
  description = "Name tag for the internet gateway"
  type        = string
  default     = "main-igw"
}

# Route Tables Configuration
variable "route_table_name_prefix" {
  description = "Prefix for route table names"
  type        = string
  default     = "rt"
}

# Security Groups Configuration
variable "security_group_name_prefix" {
  description = "Prefix for security group names"
  type        = string
  default     = "sg"
}

variable "create_alb_sg" {
  description = "Whether to create ALB security group"
  type        = bool
  default     = true
}

variable "create_web_sg" {
  description = "Whether to create web security group"
  type        = bool
  default     = true
}

variable "create_app_sg" {
  description = "Whether to create app security group"
  type        = bool
  default     = false
}

variable "create_database_sg" {
  description = "Whether to create database security group"
  type        = bool
  default     = false
}

variable "app_port" {
  description = "Port for application servers"
  type        = number
  default     = 8080
}

variable "database_port" {
  description = "Port for database servers"
  type        = number
  default     = 5432
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# IAM Configuration
variable "iam_name_prefix" {
  description = "Prefix for IAM resource names"
  type        = string
  default     = "iam"
}

variable "iam_create_ec2_role" {
  description = "Whether to create EC2 IAM role"
  type        = bool
  default     = true
}

variable "iam_create_cloudwatch_policy" {
  description = "Whether to create CloudWatch agent policy"
  type        = bool
  default     = false
}

variable "iam_create_ssm_policy" {
  description = "Whether to create SSM policy"
  type        = bool
  default     = false
}

variable "iam_create_s3_policy" {
  description = "Whether to create S3 access policy"
  type        = bool
  default     = false
}

variable "iam_s3_bucket_name" {
  description = "S3 bucket name for S3 access policy"
  type        = string
  default     = ""
}

variable "iam_custom_policy_arns" {
  description = "List of custom policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

# EC2 Configuration
variable "ec2_name_prefix" {
  description = "Prefix for EC2 resource names"
  type        = string
  default     = "ec2"
}

variable "ec2_instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ec2_ami_id" {
  description = "Custom AMI ID (if null, uses Ubuntu 24.04 LTS)"
  type        = string
  default     = null
}

variable "ec2_use_private_subnets" {
  description = "Whether to use private subnets for EC2 instances"
  type        = bool
  default     = false
}

variable "ec2_security_group_ids" {
  description = "List of security group IDs for EC2 instances"
  type        = list(string)
  default     = []
}

variable "ec2_associate_public_ip" {
  description = "Whether to associate public IP address"
  type        = bool
  default     = false
}

variable "ec2_key_name" {
  description = "Name of an existing EC2 key pair to use for SSH access"
  type        = string
  default     = null
}

variable "ec2_root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "ec2_root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "ec2_encrypt_root_volume" {
  description = "Whether to encrypt root volume"
  type        = bool
  default     = true
}

variable "ec2_user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "mlops-iac"
    ManagedBy   = "terraform"
  }
} 