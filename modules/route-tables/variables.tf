variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "database_subnet_ids" {
  description = "List of database subnet IDs"
  type        = list(string)
  default     = []
}

variable "internet_gateway_id" {
  description = "The ID of the internet gateway"
  type        = string
}

variable "create_database_subnets" {
  description = "Whether database subnets are created"
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Prefix for route table names"
  type        = string
  default     = "rt"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 