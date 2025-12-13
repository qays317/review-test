//==========================================================================================================================================
//                                                     /modules/cdn_dns/outputs.tf
//==========================================================================================================================================

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.wordpress.id
}

output "cloudfront_distribution_domain" {
  value = aws_cloudfront_distribution.wordpress.domain_name
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.wordpress.arn
}
