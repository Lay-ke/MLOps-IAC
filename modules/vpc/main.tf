# VPC Module
# This module creates a VPC with the specified CIDR block and enables DNS support

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    {
      Name = var.vpc_name
    },
    var.tags
  )
}

# Default route table
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = merge(
    {
      Name = "${var.vpc_name}-default-rt"
    },
    var.tags
  )
}