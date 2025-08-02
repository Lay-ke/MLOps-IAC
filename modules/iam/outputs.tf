output "ec2_role_name" {
  description = "Name of the EC2 IAM role"
  value       = var.create_ec2_role ? aws_iam_role.ec2_role[0].name : null
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = var.create_ec2_role ? aws_iam_role.ec2_role[0].arn : null
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = var.create_ec2_role ? aws_iam_instance_profile.ec2_profile[0].name : null
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = var.create_ec2_role ? aws_iam_instance_profile.ec2_profile[0].arn : null
}

output "cloudwatch_policy_arn" {
  description = "ARN of the CloudWatch agent policy"
  value       = var.create_cloudwatch_policy ? aws_iam_policy.cloudwatch_agent[0].arn : null
}

output "ssm_policy_arn" {
  description = "ARN of the SSM policy"
  value       = var.create_ssm_policy ? aws_iam_policy.ssm[0].arn : null
}

output "s3_policy_arn" {
  description = "ARN of the S3 access policy"
  value       = var.create_s3_policy ? aws_iam_policy.s3_access[0].arn : null
} 