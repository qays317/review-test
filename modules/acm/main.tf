//==========================================================================================================================================
//                                                               ACM
//==========================================================================================================================================

# ----------------------------------------------------------------------
# Create certificate
# ----------------------------------------------------------------------
resource "aws_acm_certificate" "cert" {
  domain_name = var.domain_name
  subject_alternative_names = [
    for san in var.subject_alternative_names : trimsuffix(san, ".")
  ]
  validation_method = "DNS"

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
  dvos = [
    for dov in aws_acm_certificate.cert.domain_validation_options : 
    {
      name = dov.resource_record_name
      type = dov.resource_record_type
      value = dov.resource_record_value
    }
  ]
}
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for index, dov in local.dvos : index => dov
  } 
  zone_id = var.hosted_zone_id
  name = each.value.name
  type = each.value.type
  ttl = 60
  records = [each.value.value]
  allow_overwrite = true
}


# ----------------------------------------------------------------------
# Certificate Validation
# ----------------------------------------------------------------------
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [
    for r in aws_route53_record.cert_validation : r.fqdn
  ]
}
