resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem

  subject {
    common_name  = try(var.tags["Project"], "MyRootCA")
    organization = try(var.tags["Team"], "MyOrg")
    country      = "GB"
    province     = "England"
    locality     = "London"
  }

  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "crl_signing"
  ]
}
