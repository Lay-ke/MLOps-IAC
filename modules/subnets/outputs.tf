output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

# output "database_subnet_ids" {
#   description = "List of database subnet IDs"
#   value       = aws_subnet.database[*].id
# }

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

# output "database_subnet_cidrs" {
#   description = "List of database subnet CIDR blocks"
#   value       = aws_subnet.database[*].cidr_block
# }

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}
