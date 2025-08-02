# Subnets Module
# This module creates public and private subnets across availability zones

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = var.az_count
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index)
  availability_zone = local.azs[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${var.name_prefix}-public-${local.azs[count.index]}"
      Tier = "Public"
    },
    var.tags
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index + var.az_count)
  availability_zone = local.azs[count.index]

  tags = merge(
    {
      Name = "${var.name_prefix}-private-${local.azs[count.index]}"
      Tier = "Private"
    },
    var.tags
  )
}

# Database Subnets (if enabled)
# resource "aws_subnet" "database" {
#   count             = var.create_database_subnets ? var.az_count : 0
#   vpc_id            = var.vpc_id
#   cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_bits, count.index + (2 * var.az_count))
#   availability_zone = local.azs[count.index]

#   tags = merge(
#     {
#       Name = "${var.name_prefix}-database-${local.azs[count.index]}"
#       Tier = "Database"
#     },
#     var.tags
#   )
# }
