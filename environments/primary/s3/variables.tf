variable "s3_bucket_name" {
    type = string
}

variable "ecs_task_role_arn" {
  type = string
  default = ""
}

variable "cloudfront_distribution_arn" {
    type = string
    default = ""
}

variable "s3_vpc_endpoint_id" {
  type = string
  default = ""
}
