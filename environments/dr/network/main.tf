//==================================================================================
// 1. Create VPC
//==================================================================================

module "network" {
  source = "../../../modules/vpc"
  vpc = var.vpc_config
  subnet = var.subnet_config
  //nat_gateway_subnet_name = var.nat_gateway_subnet_name_config
  //networkfirewall_subnet_name = var.networkfirewall_subnet_name_config
  route_table = var.route_table_config
}

