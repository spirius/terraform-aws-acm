locals {
  cert_domains       = [for k, v in var.domains : trim(v.domain, ".")]
  cert_domains_clean = [for d in local.cert_domains : replace(d, "/^\\*\\./", "")]
  cert_domains_unique = {
    for v in distinct(local.cert_domains_clean) :
    v => index(local.cert_domains_clean, v)
  }
}

resource "aws_acm_certificate" "cert" {
  lifecycle {
    create_before_destroy = true
  }

  domain_name               = local.cert_domains[0]
  subject_alternative_names = slice(local.cert_domains, 1, length(local.cert_domains))
  validation_method         = "DNS"

  tags = var.tags
}

resource "aws_route53_record" "cert" {
  for_each = local.cert_domains_unique

  allow_overwrite = true

  zone_id = var.domains[each.value].zone_id
  name    = try(aws_acm_certificate.cert.domain_validation_options[each.value].resource_record_name, "")
  type    = try(aws_acm_certificate.cert.domain_validation_options[each.value].resource_record_type, "CNAME")
  records = [try(aws_acm_certificate.cert.domain_validation_options[each.value].resource_record_value, "")]
  ttl     = var.validation_record_ttl
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = values(aws_route53_record.cert).*.fqdn
}
