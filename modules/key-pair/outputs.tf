output "key_pair_name" {
  description = "Name of the created key pair"
  value       = var.create_key_pair ? aws_key_pair.main[0].key_name : null
}

output "key_pair_id" {
  description = "ID of the created key pair"
  value       = var.create_key_pair ? aws_key_pair.main[0].id : null
}

output "key_pair_arn" {
  description = "ARN of the created key pair"
  value       = var.create_key_pair ? aws_key_pair.main[0].arn : null
} 