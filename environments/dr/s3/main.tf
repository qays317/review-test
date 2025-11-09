data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/dr/network.tfstate"
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

data "terraform_remote_state" "primary_s3" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/primary/s3.tfstate"
    region = "eu-central-1"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key = "environments/global/iam.tfstate"
    region = "eu-central-1"
  }
}

module "s3" {
    source = "../../../modules/s3"
    vpc_id = data.terraform_remote_state.network.outputs.vpc_id
    s3_bucket_name = var.s3_bucket_name
    oac_arn = data.terraform_remote_state.oac.outputs.oac_arn
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
