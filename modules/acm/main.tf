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
resource "aws_route53_record" "cert_validation" {

  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => dvo
  }

  zone_id = var.hosted_zone_id

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 60
  records = [each.value.resource_record_value]

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
