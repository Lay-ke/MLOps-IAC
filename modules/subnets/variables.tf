variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block of the VPC"
  type        = string
}

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

variable "name_prefix" {
  description = "Prefix for subnet names"
  type        = string
  default     = "subnet"
}

variable "create_database_subnets" {
  description = "Whether to create database subnets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
