variable "s3_bucket_name" {
    type = string
}

variable "ecs_task_role_arn" {
  type = string
  default = ""
  description = "ARN of the ECS task role to include as a principal in the bucket policy"
}

variable "cloudfront_media_distribution_arn" {
    type = string
    default = ""
}

variable "cloudfront_distribution_arns" {
  type    = list(string)
  default = []
  description = "List of CloudFront distribution ARNs to allow in S3 bucket policy"
}

variable "s3_vpc_endpoint_id" {
  type = string
  default = ""
  description = "ID of the S3 VPC endpoint to allow in the bucket policy"
}
