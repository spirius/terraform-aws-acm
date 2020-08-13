locals {
  cert_domains       = [for v in var.domains : trim(v.domain, ".")]
  cert_domains_clean = [for d in local.cert_domains : replace(d, "/^\\*\\./", "")]
  cert_domains_map   = { for v in var.domains : trim(v.domain, ".") => v }

  cert_domain_records = {
    for k, v in {
      for dvo in aws_acm_certificate.this.domain_validation_options :
      replace(dvo.domain_name, "/^\\*\\./", "") => dvo...
      if lookup(local.cert_domains_map, dvo.domain_name, { zone_id = null }).zone_id != null
    } :
    k => v[0]
  }

  cert_domain_records_unvalidated = {
    for k, v in {
      for dvo in aws_acm_certificate.this.domain_validation_options :
      replace(dvo.domain_name, "/^\\*\\./", "") => dvo...
      if lookup(local.cert_domains_map, dvo.domain_name, { zone_id = null }).zone_id == null
    } :
    k => v[0]
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

  for_each = local.cert_domain_records

  allow_overwrite = var.route53_allow_overwrite

  zone_id = var.domains[index(local.cert_domains_clean, each.key)].zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = var.validation_record_ttl
}

resource "aws_acm_certificate_validation" "this" {
  count = length(local.cert_domain_records) > 0 ? 1 : 0

  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = values(aws_route53_record.this).*.fqdn
}
