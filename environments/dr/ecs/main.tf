//==================================================================================
// 2. Create ECS
//==================================================================================

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/network/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/alb/terraform.tfstate"
    region = var.state_bucket_region
  }
}

module "sg_ecs" {
  source = "../../../modules/sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  security_group = var.ecs_security_group_config
  stage_tag = "ECS"
  external_security_groups = {
    ALB-SG = data.terraform_remote_state.alb.outputs.alb_security_group_id
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/global/iam/terraform.tfstate"
    region = var.state_bucket_region
  }    
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/read_replica_rds/terraform.tfstate"
    region = var.state_bucket_region
  }  
}

data "terraform_remote_state" "cdn_dns" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/global/cdn_dns/terraform.tfstate"
    region = var.state_bucket_region
  }    
}

module "ecs" {
    source = "../../../modules/ecs"
    # infrastructure data
    vpc_id = data.terraform_remote_state.network.outputs.vpc_id    
    private_subnets_ids = data.terraform_remote_state.network.outputs.private_subnets_ids  
    # RDS data           
    wordpress_secret_arn = data.terraform_remote_state.rds.outputs.wordpress_secret_arn
    # ALB data
    target_group_arn = data.terraform_remote_state.alb.outputs.target_group_arn
    target_group_arn_suffix = data.terraform_remote_state.alb.outputs.target_group_arn_suffix
    load_balancer_arn_suffix = data.terraform_remote_state.alb.outputs.alb_arn_suffix
    # Storage & CDN
    s3_bucket_name = var.dr_media_s3_bucket
    primary_domain = var.primary_domain
    cloudfront_distribution_id = data.terraform_remote_state.cdn_dns.outputs.distribution_id
    cloudfront_distribution_domain = data.terraform_remote_state.cdn_dns.outputs.distribution_domain
    # Docker image
    ecr_image_uri = var.ecr_image_uri
    # ECS configuration
    security_groups = module.sg_ecs.ecs_security_groups
    vpc_endpoints_security_group_id = module.sg_ecs.vpc_endpoints_security_group_id
    ecs_cluster_name = var.ecs_cluster_name_config
    ecs_execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_execution_role_arn
    ecs_task_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_role_arn
    ecs_task_definition = var.ecs_task_definition_config
    ecs_service = var.ecs_service_config
    # VPC Endpoints
    vpc_endpoints = var.vpc_endpoints_config
}


