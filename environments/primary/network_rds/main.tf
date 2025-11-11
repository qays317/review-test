//==================================================================================
// 1. VPC
//==================================================================================

module "network" {
  source = "../../../modules/vpc"
  vpc = var.vpc_config
  subnet = var.subnet_config
  //nat_gateway_subnet_name = var.nat_gateway_subnet_name_config
  //networkfirewall_subnet_name = var.networkfirewall_subnet_name_config
  route_table = var.route_table_config
}


//==================================================================================
// 2. Create and setup RDS database
//==================================================================================

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/global/iam.tfstate"
    region = "eu-central-1"
  }
}

module "sg_rds" {
  source = "../../../modules/sg"
  vpc_id = module.network.vpc_id
  security_group = var.rds_security_group_config
  stage_tag = "RDS"
}

module "rds" {
  source = "../../../modules/rds"
  vpc_id = module.network.vpc_id
  subnets = module.network.subnets
  private_subnets_ids = module.network.private_subnets_ids
  security_groups = module.sg_rds.rds_security_groups
  secretsmanager_endpoint_sg_name = var.secretsmanager_endpoint_sg_name_config
  lambda_security_group_name = var.lambda_security_group_name_config
  lambda_role_arn = data.terraform_remote_state.iam.outputs.lambda_db_setup_role_arn
  rds = var.rds_config
}
