variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "name_prefix" {
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 