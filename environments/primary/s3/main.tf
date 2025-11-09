//==================================================================================
//    S3
//==================================================================================

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/primary/network_rds.tfstate"
    region = "eu-central-1"
  }  
}

data "terraform_remote_state" "oac" {
    backend = "s3"
    config = {
      bucket = var.state_bucket
      key = "environments/global/oac.tfstate"
      region = "eu-central-1"
    }
}

module "s3" {
    source = "../../../modules/s3"
    vpc_id = data.terraform_remote_state.network.outputs.vpc_id
    s3_bucket_name = var.s3_bucket_name
    oac_arn = data.terraform_remote_state.oac.outputs.oac_arn
    cloudfront_media_distribution_arn = var.cloudfront_media_distribution_arn
}