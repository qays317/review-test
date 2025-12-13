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
  
  cloudfront_distribution_arn = var.cloudfront_distribution_arn
  ecs_task_role_arn = var.ecs_task_role_arn
  s3_vpc_endpoint_id = var.s3_vpc_endpoint_id
}

resource "aws_s3_bucket_replication_configuration" "primary_to_dr" {
  provider = aws.primary

  bucket = data.terraform_remote_state.primary_s3.outputs.bucket_name
  role   = data.terraform_remote_state.iam.outputs.s3_replication_role_arn

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    delete_marker_replication {
      status = "Enabled"
    }

    filter {
      prefix = ""
    }

    destination {
      bucket        = module.s3.bucket_arn
      storage_class = "STANDARD"

      metrics {
        status = "Enabled"

        # Must define event threshold or AWS fails
        event_threshold {
          minutes = 15
        }
      }

      replication_time {
        status = "Enabled"

        time {
          minutes = 15
        }
      }
    }
  }

  depends_on = [module.s3]
}

