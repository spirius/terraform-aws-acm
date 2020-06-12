output "certificate" {
  depends_on = [
    aws_acm_certificate_validation.this
  ]

  value = aws_acm_certificate.this
}
