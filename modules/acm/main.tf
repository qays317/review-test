//==========================================================================================================================================
//                                                               ACM
//==========================================================================================================================================

# ----------------------------------------------------------------------
# Create certificate
# ----------------------------------------------------------------------
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-cert-${var.environment}"
  }
}

# ----------------------------------------------------------------------
# DNS Validation Records
# ----------------------------------------------------------------------
locals {
  validation_domains = tolist(aws_acm_certificate.cert.domain_validation_options)
}
resource "aws_route53_record" "cert_validation" {
  count = length(local.validation_domains)
  zone_id = var.hosted_zone_id
  name = local.validation_domains[count.index].resource_record_name
  type = local.validation_domains[count.index].resource_record_type
  ttl = 60
  records = [local.validation_domains[count.index].resource_record_value]
}


# ----------------------------------------------------------------------
# Certificate Validation
# ----------------------------------------------------------------------
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
