resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name = "wordpress-s3-oac"
  description = "OAC for WordPress media S3"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}
