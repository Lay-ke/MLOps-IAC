# Main Terraform configuration
# This file demonstrates how to use all the network modules together

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags                 = var.tags
}

# Subnets Module
module "subnets" {
  source = "./modules/subnets"

  vpc_id                  = module.vpc.vpc_id
  vpc_cidr                = module.vpc.vpc_cidr_block
  az_count                = var.az_count
  subnet_bits             = var.subnet_bits
  name_prefix             = var.subnet_name_prefix
  # create_database_subnets = var.create_database_subnets
  tags                    = var.tags

  depends_on = [module.vpc]
}

# Internet Gateway Module
module "internet_gateway" {
  source = "./modules/internet-gateway"

  vpc_id = module.vpc.vpc_id
  name   = var.igw_name
  tags   = var.tags

  depends_on = [module.vpc]
}

# Route Tables Module
module "route_tables" {
  source = "./modules/route-tables"

  vpc_id                  = module.vpc.vpc_id
  az_count                = var.az_count
  public_subnet_ids       = module.subnets.public_subnet_ids
  private_subnet_ids      = module.subnets.private_subnet_ids
  # database_subnet_ids     = module.subnets.database_subnet_ids
  internet_gateway_id     = module.internet_gateway.internet_gateway_id
  # create_database_subnets = var.create_database_subnets
  name_prefix             = var.route_table_name_prefix
  tags                    = var.tags

  depends_on = [module.subnets, module.internet_gateway]
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security-groups"

  vpc_id             = module.vpc.vpc_id
  name_prefix        = var.security_group_name_prefix
  # create_alb_sg      = var.create_alb_sg
  create_web_sg      = var.create_web_sg
  # create_app_sg      = var.create_app_sg
  # create_database_sg = var.create_database_sg
  # app_port           = var.app_port
  # database_port      = var.database_port
  ssh_cidr_blocks    = var.ssh_cidr_blocks
  tags               = var.tags

  depends_on = [module.vpc]
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  name_prefix              = var.iam_name_prefix
  create_ec2_role          = var.iam_create_ec2_role
  create_cloudwatch_policy = var.iam_create_cloudwatch_policy
  create_ssm_policy        = var.iam_create_ssm_policy
  create_s3_policy         = var.iam_create_s3_policy
  s3_bucket_name           = var.iam_s3_bucket_name
  custom_policy_arns       = var.iam_custom_policy_arns
  tags                     = var.tags
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  name_prefix         = var.ec2_name_prefix
  instance_count      = var.ec2_instance_count
  instance_type       = var.ec2_instance_type
  ami_id              = var.ec2_ami_id
  subnet_ids          = var.ec2_use_private_subnets ? module.subnets.private_subnet_ids : module.subnets.public_subnet_ids
  security_group_ids  = [module.security_groups.web_security_group_id]
  associate_public_ip = var.ec2_associate_public_ip
  key_name            = var.ec2_key_name
  root_volume_type    = var.ec2_root_volume_type
  root_volume_size    = var.ec2_root_volume_size
  encrypt_root_volume = var.ec2_encrypt_root_volume
  user_data           = var.ec2_user_data
  tags                = var.tags

  depends_on = [module.subnets, module.security_groups, module.iam]
}
