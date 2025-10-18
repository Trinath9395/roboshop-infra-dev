module "vpc" {
  #source = "../terraformm-aws-vpc"
  source = "git::https://github.com/Trinath9395/terraformm-aws-vpc.git?ref=main"
  project_name = var.project_name
  environment = var.environment
  vpc_cidr = var.vpc_cidr
  common_tags = var.common_tags
  vpc_tags = var.vpc_tags
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  database_subnet_cidr = var.database_subnet_cidr
  is_peering_required = true 
}

resource "aws_db_subnet_group" "roboshop" {
  name = "${var.project_name}-${var.environment}"
  subnet_ids = module.vpc.database_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}"
    }
  )
}