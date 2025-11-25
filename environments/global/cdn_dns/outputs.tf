output "primary_domain" {
    value = var.primary_domain
}

output "media_distribution_id" {
  value = module.cdn_dns.media_distribution_id
}

output "media_distribution_domain" {
  value = module.cdn_dns.media_distribution_domain
}

output "media_distribution_arn" {
  value = module.cdn_dns.media_distribution_arn
}

output "app_distribution_arn" {
  value = module.cdn_dns.app_distribution_arn
}