//==================================================================================
// 1. VPC
//==================================================================================

module "network" {
  source = "../../../modules/vpc"
  vpc = var.vpc_config
  subnet = local.subnet_config
  route_table = var.route_table_config
}


//==================================================================================
// 2. Create and setup RDS database
//==================================================================================

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/global/iam/terraform.tfstate"
    region = var.state_bucket_region
  }
}

module "sg_rds" {
  source = "../../../modules/sg"
  vpc_id = module.network.vpc_id
  vpc_cidr = module.network.vpc_cidr
  security_group = var.rds_security_group_config
  stage_tag = "RDS"
}

module "rds" {
  source = "../../../modules/rds"
  # VPC configuration
  vpc_id = module.network.vpc_id
  subnets = module.network.subnets
  private_subnets_ids = module.network.private_subnets_ids
  # Lambda IAM role
  lambda_role_arn = data.terraform_remote_state.iam.outputs.lambda_db_setup_role_arn
  # SGs configuration
  security_groups = module.sg_rds.rds_security_groups
  secretsmanager_endpoint_sg_name = var.secretsmanager_endpoint_sg_name
  lambda_security_group_name = var.lambda_security_group_name
  # RDS configuration
  rds_identifier = var.rds_identifier
  rds = var.rds_config
}
