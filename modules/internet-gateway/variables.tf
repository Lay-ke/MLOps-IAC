variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "name" {
  description = "Name tag for the internet gateway"
  type        = string
  default     = "main-igw"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 