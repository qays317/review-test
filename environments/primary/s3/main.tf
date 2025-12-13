//==================================================================================
//    S3
//==================================================================================

module "s3" {
    source = "../../../modules/s3"
    
    s3_bucket_name = var.s3_bucket_name

    cloudfront_distribution_arn = var.cloudfront_distribution_arn
    ecs_task_role_arn = var.ecs_task_role_arn
    s3_vpc_endpoint_id = var.s3_vpc_endpoint_id
}