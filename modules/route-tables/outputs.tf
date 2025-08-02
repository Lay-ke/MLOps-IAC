output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

# output "database_route_table_ids" {
#   description = "List of database route table IDs"
#   value       = aws_route_table.database[*].id
# }

output "public_route_table_arn" {
  description = "The ARN of the public route table"
  value       = aws_route_table.public.arn
}

output "private_route_table_arns" {
  description = "List of private route table ARNs"
  value       = aws_route_table.private[*].arn
}

# output "database_route_table_arns" {
#   description = "List of database route table ARNs"
#   value       = aws_route_table.database[*].arn
# } 