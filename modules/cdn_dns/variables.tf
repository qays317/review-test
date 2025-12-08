//==========================================================================================================================================
//                                                     /modules/cdn_dns/variables.tf
//==========================================================================================================================================
variable "oac_id" {
    type = string
}

variable "primary_alb_dns_name" {
    type = string
}

variable "primary_alb_zone_id" {
    type = string
}

variable "dr_alb_dns_name" {
    type = string
}

variable "primary_bucket_regional_domain_name" {
    type = string
}

variable "dr_bucket_regional_domain_name" {
    type = string
}

variable "primary_domain" {
    description = "Primary custom domain without www (e.g., yourdomain.com)"
    type = string
}

# Generate both root and www domains
locals {
  domains = [var.primary_domain, "www.${var.primary_domain}"]
}

variable "ssl_certificate_arn" {                 # Used by CloudFront for SSL Termination
    description = "SSL certificate ARN for custom domain (required)"
    type = string
}

variable "hosted_zone_id" {                      # Used for creating DNS records that point the domain to CloudFront
    description = "Route 53 hosted zone ID"
    type = string
}
