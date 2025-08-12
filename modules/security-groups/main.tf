# Security Groups Module
# This module creates security groups for different tiers

# ALB Security Group
# resource "aws_security_group" "alb" {
#   count       = var.create_alb_sg ? 1 : 0
#   name        = "${var.name_prefix}-alb-sg"
#   description = "Security group for Application Load Balancer"
#   vpc_id      = var.vpc_id

#   ingress {
#     description = "HTTP from Internet"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "HTTPS from Internet"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(
#     {
#       Name = "${var.name_prefix}-alb-sg"
#       Tier = "ALB"
#     },
#     var.tags
#   )
# }

# Web Security Group
resource "aws_security_group" "web" {
  count       = var.create_web_sg ? 1 : 0
  name        = "${var.name_prefix}_web_sg"
  description = "Security group for web servers"
  vpc_id      = var.vpc_id

  # ingress {
  #   description     = "HTTP from ALB"
  #   from_port       = 80
  #   to_port         = 80
  #   protocol        = "tcp"
  #   security_groups = var.create_alb_sg ? [aws_security_group.alb[0].id] : []
  # }

  # ingress {
  #   description     = "HTTPS from ALB"
  #   from_port       = 443
  #   to_port         = 443
  #   protocol        = "tcp"
  #   security_groups = var.create_alb_sg ? [aws_security_group.alb[0].id] : []
  # }

  ingress {
    description = "SSH from specified CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  ingress {
    description = "airflow api server port"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "mlflow server port"
    from_port   = 30081
    to_port     = 30081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "inference server port"
    from_port   = 30082
    to_port     = 30082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "prometheus server port"
    from_port   = 30090
    to_port     = 30090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "grafana server port"
    from_port   = 30091
    to_port     = 30091
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.name_prefix}-web-sg"
      Tier = "Web"
    },
    var.tags
  )
}

# App Security Group
# resource "aws_security_group" "app" {
#   count       = var.create_app_sg ? 1 : 0
#   name        = "${var.name_prefix}_app_sg"
#   description = "Security group for application servers"
#   vpc_id      = var.vpc_id

#   ingress {
#     description     = "App port from Web tier"
#     from_port       = var.app_port
#     to_port         = var.app_port
#     protocol        = "tcp"
#     security_groups = var.create_web_sg ? [aws_security_group.web[0].id] : []
#   }

#   ingress {
#     description = "SSH from specified CIDR"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = var.ssh_cidr_blocks
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(
#     {
#       Name = "${var.name_prefix}-app-sg"
#       Tier = "App"
#     },
#     var.tags
#   )
# }

# Database Security Group
# resource "aws_security_group" "database" {
#   count       = var.create_database_sg ? 1 : 0
#   name        = "${var.name_prefix}_database_sg"
#   description = "Security group for database servers"
#   vpc_id      = var.vpc_id

#   ingress {
#     description     = "Database port from App tier"
#     from_port       = var.database_port
#     to_port         = var.database_port
#     protocol        = "tcp"
#     security_groups = var.create_app_sg ? [aws_security_group.app[0].id] : []
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(
#     {
#       Name = "${var.name_prefix}-database-sg"
#       Tier = "Database"
#     },
#     var.tags
#   )
# } 