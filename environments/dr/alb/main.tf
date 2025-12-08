//==================================================================================
//  Create ALB
//==================================================================================

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/network/terraform.tfstate"
    region = var.state_bucket_region
  }  
}

module "sg_alb" {
  source = "../../../modules/sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
  security_group = var.alb_security_group_config
  stage_tag = "ALB"
}

module "cert" {
  count = var.provided_ssl_certificate_arn == "" ? 1 : 0
  source = "../../../modules/acm"

  domain_name = var.primary_domain
  subject_alternative_names = ["www.${var.primary_domain}"]
  hosted_zone_id = var.hosted_zone_id
  environment = "dr"
}

module "alb" {
  source = "../../../modules/alb"
  # VPC configuration
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets_ids
  # ALB configuration
  alb_security_group_id = module.sg_alb.alb_security_group_id
  target_group = var.target_group_config
  alb_name = var.alb_name
  # SSL certificate (whether to create it or already provided)
  ssl_certificate_arn = var.provided_ssl_certificate_arn != "" ? var.provided_ssl_certificate_arn : module.cert[0].certificate_arn
}
