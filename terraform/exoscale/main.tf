locals {
  name_prefix = "${var.project_name}-${var.environment}"

  mimir_bucket  = var.enable_mimir_bucket ? (var.mimir_bucket_name != "" ? var.mimir_bucket_name : "${local.name_prefix}-mimir-${random_id.bucket_suffix.hex}") : ""
  loki_bucket   = var.enable_loki_bucket ? (var.loki_bucket_name != "" ? var.loki_bucket_name : "${local.name_prefix}-loki-${random_id.bucket_suffix.hex}") : ""
  tempo_bucket  = var.enable_tempo_bucket ? (var.tempo_bucket_name != "" ? var.tempo_bucket_name : "${local.name_prefix}-tempo-${random_id.bucket_suffix.hex}") : ""
  backup_bucket = var.enable_backup_bucket ? (var.backup_bucket_name != "" ? var.backup_bucket_name : "${local.name_prefix}-backups-${random_id.bucket_suffix.hex}") : ""

  # Fixed ports - not configurable
  wizard_port       = 9443
  grafana_port      = 443
  loki_port         = 3100
  otel_grpc_port    = 4317
  otel_http_port    = 4318
  tempo_http_port   = 3200
  tempo_grpc_port   = 9095
  mimir_port        = 9009
  prometheus_port   = 9090
  alertmanager_port = 9093

  stack_name = "dm-${random_id.stack_suffix.hex}"

  # SOS endpoint for the zone
  sos_endpoint = "https://sos-${var.zone}.exo.io"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "random_id" "stack_suffix" {
  byte_length = 4
}

# Data source to get the Ubuntu template
data "exoscale_template" "ubuntu" {
  zone = var.zone
  name = var.template_name
}

# Security group for monitoring stack
resource "exoscale_security_group" "monitoring" {
  name = "${local.name_prefix}-monitoring-sg"
}

# Allow all traffic from same security group (inter-instance communication)
resource "exoscale_security_group_rule" "private" {
  security_group_id      = exoscale_security_group.monitoring.id
  type                   = "INGRESS"
  protocol               = "TCP"
  start_port             = 1
  end_port               = 65535
  user_security_group_id = exoscale_security_group.monitoring.id
  description            = "Allow all from same security group"
}

# SSH access
resource "exoscale_security_group_rule" "ssh" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = 22
  end_port          = 22
  cidr              = var.allowed_external_cidrs[0]
  description       = "SSH access"
}

# Wizard port
resource "exoscale_security_group_rule" "wizard" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.wizard_port
  end_port          = local.wizard_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "Wizard access"
}

# Grafana HTTPS
resource "exoscale_security_group_rule" "grafana" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.grafana_port
  end_port          = local.grafana_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "Grafana HTTPS"
}

# Loki
resource "exoscale_security_group_rule" "loki" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.loki_port
  end_port          = local.loki_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "Loki"
}

# OpenTelemetry gRPC
resource "exoscale_security_group_rule" "otel_grpc" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.otel_grpc_port
  end_port          = local.otel_grpc_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "OpenTelemetry gRPC"
}

# OpenTelemetry HTTP
resource "exoscale_security_group_rule" "otel_http" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.otel_http_port
  end_port          = local.otel_http_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "OpenTelemetry HTTP"
}

# Tempo HTTP
resource "exoscale_security_group_rule" "tempo_http" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.tempo_http_port
  end_port          = local.tempo_http_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "Tempo HTTP"
}

# Tempo gRPC
resource "exoscale_security_group_rule" "tempo_grpc" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.tempo_grpc_port
  end_port          = local.tempo_grpc_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "Tempo gRPC"
}

# Mimir
resource "exoscale_security_group_rule" "mimir" {
  count = length(var.allowed_external_cidrs) > 0 ? 1 : 0

  security_group_id = exoscale_security_group.monitoring.id
  type              = "INGRESS"
  protocol          = "TCP"
  start_port        = local.mimir_port
  end_port          = local.mimir_port
  cidr              = var.allowed_external_cidrs[0]
  description       = "Mimir"
}

# Generate SSH key for instances
resource "tls_private_key" "ssh" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

# Compute instances
resource "exoscale_compute_instance" "monitoring" {
  count = var.instance_count

  zone = var.zone
  name = "${local.name_prefix}-${count.index + 1}"
  type = var.instance_type

  template_id = var.template_id != null ? var.template_id : data.exoscale_template.ubuntu.id
  disk_size   = var.disk_size

  security_group_ids = [exoscale_security_group.monitoring.id]

  ssh_key = var.ssh_key_name != "" ? var.ssh_key_name : null

  ipv6 = var.enable_ipv6

  user_data = var.user_data_script != "" ? var.user_data_script : templatefile("${path.module}/user_data.sh", {
    ssh_private_key       = tls_private_key.ssh.private_key_pem,
    ssh_public_key        = tls_private_key.ssh.public_key_openssh,
    mimir_bucket          = try(aws_s3_bucket.mimir[0].id, local.mimir_bucket),
    loki_bucket           = try(aws_s3_bucket.loki[0].id, local.loki_bucket),
    tempo_bucket          = try(aws_s3_bucket.tempo[0].id, local.tempo_bucket),
    backup_bucket         = try(aws_s3_bucket.backup[0].id, local.backup_bucket),
    zone                  = var.zone,
    role                  = replace(var.role, "-", "_"),
    sos_endpoint          = local.sos_endpoint,
    tls_private_key       = tls_private_key.ca_key.private_key_pem,
    tls_cert              = tls_self_signed_cert.ca_cert.cert_pem,
    stack                 = local.stack_name,
    aws_access_key        = try(exoscale_iam_api_key.s3[0].key, "")
    aws_secret_access_key = try(exoscale_iam_api_key.s3[0].secret, "")
  })

  labels = merge(
    {
      role          = var.role
      stack         = local.stack_name
      mimir_bucket  = local.mimir_bucket
      loki_bucket   = local.loki_bucket
      tempo_bucket  = local.tempo_bucket
      backup_bucket = local.backup_bucket
    },
    var.tags
  )
}

# S3 buckets using AWS provider configured for Exoscale SOS
resource "aws_s3_bucket" "mimir" {
  count = var.enable_mimir_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket        = local.mimir_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.mimir_bucket
      Purpose = "Mimir Storage"
    },
    var.tags
  )
}

resource "aws_s3_bucket_acl" "mimir" {
  count = var.enable_mimir_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket = aws_s3_bucket.mimir[0].id
  acl    = "private"
}

resource "aws_s3_bucket" "loki" {
  count = var.enable_loki_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket        = local.loki_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.loki_bucket
      Purpose = "Loki Storage"
    },
    var.tags
  )
}

resource "aws_s3_bucket_acl" "loki" {
  count = var.enable_loki_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket = aws_s3_bucket.loki[0].id
  acl    = "private"
}

resource "aws_s3_bucket" "tempo" {
  count = var.enable_tempo_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket        = local.tempo_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.tempo_bucket
      Purpose = "Tempo Storage"
    },
    var.tags
  )
}

resource "aws_s3_bucket_acl" "tempo" {
  count = var.enable_tempo_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket = aws_s3_bucket.tempo[0].id
  acl    = "private"
}

resource "aws_s3_bucket" "backup" {
  count = var.enable_backup_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket        = local.backup_bucket
  force_destroy = var.bucket_force_destroy

  tags = merge(
    {
      Name    = local.backup_bucket
      Purpose = "Backups"
    },
    var.tags
  )
}

resource "aws_s3_bucket_acl" "backup" {
  count = var.enable_backup_bucket ? 1 : 0

  provider = aws.exoscale_sos

  bucket = aws_s3_bucket.backup[0].id
  acl    = "private"
}

resource "exoscale_iam_role" "s3" {
  count       = (var.enable_backup_bucket || var.enable_tempo_bucket || var.enable_mimir_bucket || var.enable_loki_bucket) ? 1 : 0
  name        = "${local.name_prefix}-s3"
  description = "Role for S3"
  editable    = true

  policy = {
    default_service_strategy = "deny"
    services = {
      sos = {
        type = "allow"
      }
    }
  }
}

resource "exoscale_iam_api_key" "s3" {
  count   = (var.enable_backup_bucket || var.enable_tempo_bucket || var.enable_mimir_bucket || var.enable_loki_bucket) ? 1 : 0
  name    = "${local.name_prefix}-s3"
  role_id = exoscale_iam_role.s3[0].id
}
