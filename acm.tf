locals {
  cert_domains       = [for k, v in var.domains : trim(v.domain, ".")]
  cert_domains_clean = [for d in local.cert_domains : replace(d, "/^\\*\\./", "")]

  cert_domains_records = {
    for domain in distinct(local.cert_domains_clean) :
    domain => [
      for dvo in aws_acm_certificate.this.domain_validation_options :
      dvo if replace(dvo.domain_name, "/^\\*\\./", "") == domain
    ][0]
  }

  tags = merge({ Name = local.cert_domains[0] }, var.tags)
}

resource "aws_acm_certificate" "this" {
  lifecycle {
    create_before_destroy = true
  }

  domain_name               = local.cert_domains[0]
  subject_alternative_names = toset(slice(local.cert_domains, 1, length(local.cert_domains)))
  validation_method         = "DNS"

  tags = var.tags
}

resource "aws_route53_record" "this" {
  provider = aws.route53

  for_each = local.cert_domains_records

  allow_overwrite = true

  zone_id = var.domains[index(local.cert_domains_clean, each.key)].zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = var.validation_record_ttl
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = values(aws_route53_record.this).*.fqdn
}
