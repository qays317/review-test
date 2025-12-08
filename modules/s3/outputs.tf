//==========================================================================================================================================
//                                                      /modules/s3/outputs.tf
//==========================================================================================================================================

output "bucket_name" {
  value = aws_s3_bucket.wordpress_media.bucket                  # For task definition (environment variables in container definition)
}

output "bucket_arn" {                                           # For S3 replication configuration
  value = aws_s3_bucket.wordpress_media.arn
}

output "bucket_regional_domain_name" {                          # For CloudFront distribution origin
  value = aws_s3_bucket.wordpress_media.bucket_regional_domain_name
}