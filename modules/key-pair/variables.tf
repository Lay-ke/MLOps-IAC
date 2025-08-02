variable "create_key_pair" {
  description = "Whether to create a new key pair in AWS (set to false to use existing key pair)"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of the key pair (existing or to be created)"
  type        = string
}

variable "public_key" {
  description = "Public key content from your local SSH key file (e.g., ~/.ssh/id_rsa.pub). Required only if create_key_pair = true"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 