//==========================================================================================================================================
//                                                     /modules/cdn_dns/outputs.tf
//==========================================================================================================================================

output "distribution_id" {
  value = aws_cloudfront_distribution.wordpress.id
}

output "distribution_domain" {
  value = aws_cloudfront_distribution.wordpress.domain_name
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.wordpress.arn
}
