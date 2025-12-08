//==========================================================================================================================================
//                                                     /modules/cdn_dns/outputs.tf
//==========================================================================================================================================
/*
output "media_distribution_id" {
  value = aws_cloudfront_distribution.main["wordpress-media"].id
}

output "media_distribution_domain" {
  value = aws_cloudfront_distribution.main["wordpress-media"].domain_name
}

output "media_distribution_arn" {
  value = aws_cloudfront_distribution.main["wordpress-media"].arn
}

output "app_distribution_arn" {
  value = aws_cloudfront_distribution.main["wordpress-app"].arn
}*/


output "distribution_id" {
  value = aws_cloudfront_distribution.wordpress.id
}

output "distribution_domain" {
  value = aws_cloudfront_distribution.wordpress.domain_name
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.wordpress.arn
}
