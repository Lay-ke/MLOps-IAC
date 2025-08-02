# Route Tables Module
# This module creates route tables for public and private subnets

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = merge(
    {
      Name = "${var.name_prefix}-public-rt"
      Tier = "Public"
    },
    var.tags
  )
}

# Private Route Tables (one per AZ)
resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = var.vpc_id

  tags = merge(
    {
      Name = "${var.name_prefix}-private-rt-${count.index + 1}"
      Tier = "Private"
    },
    var.tags
  )
}

# Database Route Tables (if enabled)
# resource "aws_route_table" "database" {
#   count  = var.create_database_subnets ? var.az_count : 0
#   vpc_id = var.vpc_id

#   tags = merge(
#     {
#       Name = "${var.name_prefix}-database-rt-${count.index + 1}"
#       Tier = "Database"
#     },
#     var.tags
#   )
# }

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[count.index].id
}

# Route Table Associations - Database
# resource "aws_route_table_association" "database" {
#   count          = var.create_database_subnets ? var.az_count : 0
#   subnet_id      = var.database_subnet_ids[count.index]
#   route_table_id = aws_route_table.database[count.index].id
# } 