########################################
# AWS Security Groups for RoboShop Project
# Environment: ${var.environment}
# Author: Trinath
########################################

# -----------------------------
# Security Group Modules
# -----------------------------
module "mysql_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "mysql"
  sg_description = "Security Group for MySQL instances"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "bastion_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "bastion"
  sg_description = "Security Group for Bastion Host"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "frontend_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "frontend"
  sg_description = "Security Group for Frontend instances"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "alb_ingress_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "alb-ingress"
  sg_description = "Security Group for ALB ingress"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "app_alb_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "app-alb"
  sg_description = "Security Group for Application ALB"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "web_alb_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "web-alb"
  sg_description = "Security Group for Web ALB"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "eks_control_plane_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "eks-control-plane"
  sg_description = "Security Group for EKS Control Plane"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

module "eks_node_sg" {
  source         = "git::https://github.com/Trinath9395/terraform-aws-sgroup.git?ref=main"
  project_name   = var.project_name
  environment    = var.environment
  sg_name        = "eks-node"
  sg_description = "Security Group for EKS Node Group"
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  common_tags    = var.common_tags
}

# -----------------------------
# Security Group Rules
# -----------------------------

# EKS <-> EKS Communication
resource "aws_security_group_rule" "eks_control_plane_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks_node_sg.sg_id
  security_group_id        = module.eks_control_plane_sg.sg_id
}

resource "aws_security_group_rule" "eks_node_eks_control_plane" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.eks_control_plane_sg.sg_id
  security_group_id        = module.eks_node_sg.sg_id
}

# EKS Node access within VPC
resource "aws_security_group_rule" "node_vpc" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # Allow all (needed for DNS resolution and pod networking)
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = module.eks_node_sg.sg_id
}

# Bastion -> EKS Node (SSH)
resource "aws_security_group_rule" "node_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.eks_node_sg.sg_id
}

# ALB ingress (from Bastion & Public)
resource "aws_security_group_rule" "alb_ingress_bastion" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.alb_ingress_sg.sg_id
}

resource "aws_security_group_rule" "alb_ingress_bastion_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.alb_ingress_sg.sg_id
}

resource "aws_security_group_rule" "alb_ingress_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.alb_ingress_sg.sg_id
}

# Bastion Public Access (SSH)
resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion_sg.sg_id
}

# MySQL Access Rules
resource "aws_security_group_rule" "mysql_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.mysql_sg.sg_id
}

resource "aws_security_group_rule" "mysql_eks_node" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.eks_node_sg.sg_id
  security_group_id        = module.mysql_sg.sg_id
}

# Bastion -> EKS Control Plane
resource "aws_security_group_rule" "eks_control_plane_bastion" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.bastion_sg.sg_id
  security_group_id        = module.eks_control_plane_sg.sg_id
}

# ALB -> EKS Node (App Traffic)
resource "aws_security_group_rule" "eks_node_alb_ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = module.alb_ingress_sg.sg_id
  security_group_id        = module.eks_node_sg.sg_id
}
