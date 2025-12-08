//==========================================================================================================================================
//                                                   /modules/s3/variables.tf
//==========================================================================================================================================

variable "s3_bucket_name" {
    type = string
}

variable "cloudfront_media_distribution_arn" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
  description = "ARN of the ECS task role to include as a principal in the bucket policy (optional)."
}

variable "s3_vpc_endpoint_id" {
  type = string
  description = "S3 VPC Endpoint id (vpce-...) to allow via aws:SourceVpce in the bucket policy (optional)."
}