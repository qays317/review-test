//==========================================================================================================================================
//                                                          CloudFront + Route 53
//==========================================================================================================================================

resource "aws_cloudfront_distribution" "wordpress" {

  # ==============================
  # ORIGINS (S3 Primary + DR)
  # ==============================
  origin {
    domain_name = var.primary_bucket_regional_domain_name
    origin_id = "S3-Primary"
    origin_access_control_id = var.oac_id
  }

  origin {
    domain_name = var.dr_bucket_regional_domain_name
    origin_id = "S3-DR"
    origin_access_control_id = var.oac_id
  }

  origin_group {
    origin_id = "S3-Group"

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "S3-Primary"
    }
    member {
      origin_id = "S3-DR"
    }
  }

  # ==============================
  # ORIGINS (ALB Primary + DR)
  # ==============================
  origin {
    domain_name = var.primary_alb_dns_name
    origin_id = "ALB-Primary"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
      origin_read_timeout = 60
      origin_keepalive_timeout = 10
    }
  }

  origin {
    domain_name = var.dr_alb_dns_name
    origin_id = "ALB-DR"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
      origin_read_timeout = 60
      origin_keepalive_timeout = 10
    }
  }

  origin_group {
    origin_id = "ALB-Group"

    failover_criteria {
      status_codes = [403, 404, 500, 502, 503, 504]
    }

    member {
      origin_id = "ALB-Primary"
    }
    member {
      origin_id = "ALB-DR"
    }
  }

  # ==============================
  # MEDIA BEHAVIOR → S3
  # ==============================
  ordered_cache_behavior {
    path_pattern = "/wp-content/uploads/*"
    target_origin_id = "S3-Group"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD"]
    compress = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl = 0
    default_ttl = 86400   # 1 day
    max_ttl = 31536000    # 1 year
  }

  # ==============================
  # DEFAULT → ALB (website)
  # ==============================
  default_cache_behavior {
    target_origin_id = "ALB-Group"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods = ["GET", "HEAD"]
    compress = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Host", "CloudFront-Forwarded-Proto"]
    }

    min_ttl = 0
    default_ttl = 0   # dynamic pages no caching
    max_ttl = 300
  }

  # ==============================
  # General Settings
  # ==============================
  custom_error_response {
    error_code = 500
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code = 502
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code = 503
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code = 504
    error_caching_min_ttl = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.ssl_certificate_arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = local.domains

  enabled = true
  comment = "WordPress CDN (app + media)"
  tags = { Name = "wordpress" }
}



//==========================================================================================================================================
//                                                             Route 53
//==========================================================================================================================================

# Route 53 DNS records for www and root domains
resource "aws_route53_record" "main" {
  for_each = toset(local.domains)
  zone_id = var.hosted_zone_id
  name = each.value
  type = "A"
  alias {
    name = aws_cloudfront_distribution.wordpress.domain_name
    zone_id = "Z2FDTNDATAQYW2"         # CloudFront's global hosted zone ID
    evaluate_target_health = false     # CloudFront handles its own health checks and failover
  }
}

# Route 53 record for admin subdomain - points directly to ALB (bypasses CloudFront)
resource "aws_route53_record" "admin_subdomain" {
  zone_id = var.hosted_zone_id
  name = "admin.${var.primary_domain}"
  type = "A"
  
  alias {
    name = var.primary_alb_dns_name
    zone_id = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}
