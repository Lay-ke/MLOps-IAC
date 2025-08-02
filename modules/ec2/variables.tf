variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "ec2"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Custom AMI ID (if null, uses Ubuntu 24.04 LTS)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for EC2 instances"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for EC2 instances"
  type        = list(string)
  default     = []
}

variable "associate_public_ip" {
  description = "Whether to associate public IP address"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of an existing EC2 key pair to use for SSH access"
  type        = string
  default     = null
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to attach"
  type        = string
  default     = null
}

variable "root_volume_type" {
  description = "Type of root volume"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "delete_root_volume_on_termination" {
  description = "Whether to delete root volume on instance termination"
  type        = bool
  default     = true
}

variable "encrypt_root_volume" {
  description = "Whether to encrypt root volume"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script for EC2 instances"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 