output "certificate" {
  depends_on = [
    aws_acm_certificate_validation.this
  ]

  value = aws_acm_certificate.this
}

output "unvalidated_domains" {
  value = local.cert_domain_records_unvalidated
}
