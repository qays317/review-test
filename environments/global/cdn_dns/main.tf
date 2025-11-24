data "terraform_remote_state" "oac" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/global/oac/terraform.tfstate"
    region = var.state_bucket_region
  }  
}

data "terraform_remote_state" "primary_s3" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/s3/terraform.tfstate"
    region = var.state_bucket_region
  }  
}

data "terraform_remote_state" "dr_s3" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/s3/terraform.tfstate"
    region = var.state_bucket_region
  }  
}

data "terraform_remote_state" "primary_alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/alb/terraform.tfstate"
    region = var.state_bucket_region
  }
}

data "terraform_remote_state" "dr_alb" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/alb/terraform.tfstate"
    region = var.state_bucket_region
  }
}

module "cloudfront_cert" {
  count = var.provided_ssl_certificate_arn != "" ? 0 :1
  source = "../../../modules/acm"

  domain_name = var.primary_domain
  subject_alternative_names = ["www.${var.primary_domain}"]
  hosted_zone_id = var.hosted_zone_id
  environment = "CDN"

}

module "cdn_dns" {
  source = "../../../modules/cdn_dns"

  # Primary origins_naame
  primary_alb_dns_name = data.terraform_remote_state.primary_alb.outputs.alb_dns_name
  primary_alb_zone_id = data.terraform_remote_state.primary_alb.outputs.alb_zone_id

  # DR origins
  dr_alb_dns_name = data.terraform_remote_state.dr_alb.outputs.alb_dns_name

  # S3 origins
  primary_bucket_regional_domain_name = data.terraform_remote_state.primary_s3.outputs.bucket_regional_domain_name
  dr_bucket_regional_domain_name = data.terraform_remote_state.dr_s3.outputs.bucket_regional_domain_name

  oac_id = data.terraform_remote_state.oac.outputs.oac_id
  cloudfront_distribution = var.cloudfront_distribution_config
  primary_domain = var.primary_domain
  hosted_zone_id = var.hosted_zone_id
  ssl_certificate_arn = var.provided_ssl_certificate_arn != "" ? var.provided_ssl_certificate_arn : module.cloudfront_cert.certificate_arn
}