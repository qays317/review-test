output "oac_arn" {
    value = aws_cloudfront_origin_access_control.s3_oac.arn  
}

output "oac_id" {                           # For CloudFront Distribution S3 origin
    value = aws_cloudfront_origin_access_control.s3_oac.id
}