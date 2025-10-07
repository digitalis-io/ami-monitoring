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

  # Hetzner Object Storage endpoint
  s3_storage_endpoint = var.enable_object_storage ? "https://${var.object_storage_region}.your-objectstorage.com" : ""
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "random_id" "stack_suffix" {
  byte_length = 4
}

# SSH key for instances
resource "hcloud_ssh_key" "monitoring" {
  count = var.ssh_key_name == "" ? 1 : 0

  name       = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh

  labels = merge(
    {
      role = var.role
    },
    var.tags
  )
}

# Data source to get existing SSH key if provided
data "hcloud_ssh_key" "existing" {
  count = var.ssh_key_name != "" ? 1 : 0

  name = var.ssh_key_name
}

# Private network (optional)
resource "hcloud_network" "monitoring" {
  count = var.enable_private_network ? 1 : 0

  name     = "${local.name_prefix}-network"
  ip_range = var.private_network_subnet

  labels = merge(
    {
      role = var.role
    },
    var.tags
  )
}

resource "hcloud_network_subnet" "monitoring" {
  count = var.enable_private_network ? 1 : 0

  network_id   = hcloud_network.monitoring[0].id
  type         = "cloud"
  network_zone = var.location == "hil" || var.location == "ash" ? "us-east" : "eu-central"
  ip_range     = cidrsubnet(var.private_network_subnet, 8, 1)
}

# Placement group for distributing instances across physical hosts
resource "hcloud_placement_group" "monitoring" {
  count = var.enable_placement_group ? 1 : 0

  name = "${local.name_prefix}-placement"
  type = "spread"

  labels = merge(
    {
      role = var.role
    },
    var.tags
  )
}

# Firewall for monitoring stack
resource "hcloud_firewall" "monitoring" {
  name = "${local.name_prefix}-firewall"

  # Allow all traffic from same firewall (inter-instance communication)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "1-65535"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "1-65535"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # ICMP for ping
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  labels = merge(
    {
      role = var.role
    },
    var.tags
  )
}

# Additional volume for each instance
resource "hcloud_volume" "monitoring" {
  count = var.disk_size > 0 ? var.instance_count : 0

  name     = "${local.name_prefix}-volume-${count.index + 1}"
  size     = var.disk_size
  location = var.location
  format   = "ext4"

  labels = merge(
    {
      role  = var.role
      stack = local.stack_name
    },
    var.tags
  )
}

# Compute instances
resource "hcloud_server" "monitoring" {
  count = var.instance_count

  name        = "${local.name_prefix}-${count.index + 1}"
  server_type = var.server_type
  location    = var.location
  image       = var.image_name

  ssh_keys = var.ssh_key_name != "" ? [data.hcloud_ssh_key.existing[0].id] : [hcloud_ssh_key.monitoring[0].id]

  firewall_ids = [hcloud_firewall.monitoring.id]

  placement_group_id = var.enable_placement_group ? hcloud_placement_group.monitoring[0].id : null

  public_net {
    ipv4_enabled = true
    ipv6_enabled = var.enable_ipv6
  }

  user_data = var.user_data_script != "" ? var.user_data_script : templatefile("${path.module}/user_data.sh", {
    ssh_private_key       = tls_private_key.ssh.private_key_pem,
    ssh_public_key        = tls_private_key.ssh.public_key_openssh,
    mimir_bucket          = try(minio_s3_bucket.mimir[0].bucket, local.mimir_bucket),
    loki_bucket           = try(minio_s3_bucket.loki[0].bucket, local.loki_bucket),
    tempo_bucket          = try(minio_s3_bucket.tempo[0].bucket, local.tempo_bucket),
    backup_bucket         = try(minio_s3_bucket.backup[0].bucket, local.backup_bucket),
    location              = var.location,
    role                  = replace(var.role, "-", "_"),
    s3_endpoint           = local.s3_storage_endpoint,
    tls_private_key       = tls_private_key.ca_key.private_key_pem,
    tls_cert              = tls_self_signed_cert.ca_cert.cert_pem,
    stack                 = local.stack_name,
    aws_access_key        = var.object_storage_access_key,
    aws_secret_access_key = var.object_storage_secret_key,
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

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Attach volumes to instances
resource "hcloud_volume_attachment" "monitoring" {
  count = var.disk_size > 0 ? var.instance_count : 0

  volume_id = hcloud_volume.monitoring[count.index].id
  server_id = hcloud_server.monitoring[count.index].id
  automount = true
}

# Attach servers to private network
resource "hcloud_server_network" "monitoring" {
  count = var.enable_private_network ? var.instance_count : 0

  server_id  = hcloud_server.monitoring[count.index].id
  network_id = hcloud_network.monitoring[0].id
}

# S3 buckets using MinIO provider for Hetzner Object Storage
resource "minio_s3_bucket" "mimir" {
  count = var.enable_mimir_bucket && var.enable_object_storage ? 1 : 0

  bucket        = local.mimir_bucket
  force_destroy = var.bucket_force_destroy
  acl           = "private"
}

resource "minio_s3_bucket" "loki" {
  count = var.enable_loki_bucket && var.enable_object_storage ? 1 : 0

  bucket        = local.loki_bucket
  force_destroy = var.bucket_force_destroy
  acl           = "private"
}

resource "minio_s3_bucket" "tempo" {
  count = var.enable_tempo_bucket && var.enable_object_storage ? 1 : 0

  bucket        = local.tempo_bucket
  force_destroy = var.bucket_force_destroy
  acl           = "private"
}

resource "minio_s3_bucket" "backup" {
  count = var.enable_backup_bucket && var.enable_object_storage ? 1 : 0

  bucket        = local.backup_bucket
  force_destroy = var.bucket_force_destroy
  acl           = "private"
}
