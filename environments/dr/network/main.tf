//==================================================================================
// 1. Create VPC
//==================================================================================

module "network" {
  source = "../../../modules/vpc"
  vpc = var.vpc_config
  subnet = var.subnet_config
  route_table = var.route_table_config
}

