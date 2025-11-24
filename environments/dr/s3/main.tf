data "terraform_remote_state" "primary_s3" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/s3/terraform.tfstate"
    region = var.state_bucket_region
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

module "s3" {
  source = "../../../modules/s3"
  s3_bucket_name = var.s3_bucket_name
  cloudfront_distribution_arns = var.cloudfront_distribution_arns
  ecs_task_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_role_arn
}

# Cross-region replication from primary to DR
resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  provider = aws.primary
  
  role = data.terraform_remote_state.iam.outputs.s3_replication_role_arn
  bucket = data.terraform_remote_state.primary_s3.outputs.bucket_name

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    destination {
      bucket = module.s3.bucket_arn
    }
  }

  depends_on = [module.s3]
}
