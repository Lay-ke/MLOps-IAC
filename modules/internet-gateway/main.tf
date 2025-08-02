# Internet Gateway Module
# This module creates an internet gateway and attaches it to the VPC

resource "aws_internet_gateway" "main" {
  vpc_id = var.vpc_id

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
} 