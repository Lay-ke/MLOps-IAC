# Key Pair Module
# This module creates EC2 key pairs

# Key Pair
resource "aws_key_pair" "main" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = var.key_name
  public_key = var.public_key

  tags = merge(
    {
      Name = var.key_name
    },
    var.tags
  )
} 