variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "iam"
}

variable "create_ec2_role" {
  description = "Whether to create EC2 IAM role"
  type        = bool
  default     = true
}

variable "create_cloudwatch_policy" {
  description = "Whether to create CloudWatch agent policy"
  type        = bool
  default     = false
}

variable "create_ssm_policy" {
  description = "Whether to create SSM policy"
  type        = bool
  default     = false
}

variable "create_s3_policy" {
  description = "Whether to create S3 access policy"
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "S3 bucket name for S3 access policy"
  type        = string
  default     = ""
}

variable "custom_policy_arns" {
  description = "List of custom policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 