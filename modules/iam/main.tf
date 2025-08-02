# Basic IAM Module
# This module creates IAM roles, policies, and instance profiles

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.name_prefix}-ec2-role"
    },
    var.tags
  )
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-profile"
  role  = aws_iam_role.ec2_role[0].name
}

# CloudWatch Agent Policy
resource "aws_iam_policy" "cloudwatch_agent" {
  count = var.create_cloudwatch_policy ? 1 : 0
  name  = "${var.name_prefix}-cloudwatch-agent-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.name_prefix}-cloudwatch-agent-policy"
    },
    var.tags
  )
}

# SSM Policy
resource "aws_iam_policy" "ssm" {
  count = var.create_ssm_policy ? 1 : 0
  name  = "${var.name_prefix}-ssm-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.name_prefix}-ssm-policy"
    },
    var.tags
  )
}

# S3 Access Policy
resource "aws_iam_policy" "s3_access" {
  count = var.create_s3_policy ? 1 : 0
  name  = "${var.name_prefix}-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.name_prefix}-s3-access-policy"
    },
    var.tags
  )
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count      = var.create_ec2_role && var.create_cloudwatch_policy ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = aws_iam_policy.cloudwatch_agent[0].arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.create_ec2_role && var.create_ssm_policy ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = aws_iam_policy.ssm[0].arn
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  count      = var.create_ec2_role && var.create_s3_policy ? 1 : 0
  role       = aws_iam_role.ec2_role[0].name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

# Custom policies attachment
resource "aws_iam_role_policy_attachment" "custom_policies" {
  for_each = var.create_ec2_role ? toset(var.custom_policy_arns) : []

  role       = aws_iam_role.ec2_role[0].name
  policy_arn = each.value
} 