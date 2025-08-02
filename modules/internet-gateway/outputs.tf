output "internet_gateway_id" {
  description = "The ID of the internet gateway"
  value       = aws_internet_gateway.main.id
}

output "internet_gateway_arn" {
  description = "The ARN of the internet gateway"
  value       = aws_internet_gateway.main.arn
} 