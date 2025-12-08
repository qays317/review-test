//==================================================================================
// Create VPC
//==================================================================================

module "network" {
  source = "../../../modules/vpc"
  vpc = var.vpc_config
  subnet = local.subnet_config
  route_table = var.route_table_config
}

