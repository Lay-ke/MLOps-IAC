# output "alb_security_group_id" {
#   description = "The ID of the ALB security group"
#   value       = var.create_alb_sg ? aws_security_group.alb[0].id : null
# }

output "web_security_group_id" {
  description = "The ID of the web security group"
  value       = var.create_web_sg ? aws_security_group.web[0].id : null
}

# output "app_security_group_id" {
#   description = "The ID of the app security group"
#   value       = var.create_app_sg ? aws_security_group.app[0].id : null
# }

# output "database_security_group_id" {
#   description = "The ID of the database security group"
#   value       = var.create_database_sg ? aws_security_group.database[0].id : null
# }

# output "alb_security_group_arn" {
#   description = "The ARN of the ALB security group"
#   value       = var.create_alb_sg ? aws_security_group.alb[0].arn : null
# }

output "web_security_group_arn" {
  description = "The ARN of the web security group"
  value       = var.create_web_sg ? aws_security_group.web[0].arn : null
}

# output "app_security_group_arn" {
#   description = "The ARN of the app security group"
#   value       = var.create_app_sg ? aws_security_group.app[0].arn : null
# }

# output "database_security_group_arn" {
#   description = "The ARN of the database security group"
#   value       = var.create_database_sg ? aws_security_group.database[0].arn : null
# } 