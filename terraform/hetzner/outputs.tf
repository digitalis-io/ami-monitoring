output "server_ids" {
  description = "IDs of monitoring servers"
  value       = hcloud_server.monitoring[*].id
}

output "server_names" {
  description = "Names of monitoring servers"
  value       = hcloud_server.monitoring[*].name
}

output "server_public_ipv4" {
  description = "Public IPv4 addresses of monitoring servers"
  value       = hcloud_server.monitoring[*].ipv4_address
}

output "server_public_ipv6" {
  description = "Public IPv6 addresses of monitoring servers"
  value       = var.enable_ipv6 ? hcloud_server.monitoring[*].ipv6_address : []
}

output "server_private_ips" {
  description = "Private IP addresses of monitoring servers (if using private network)"
  value       = var.enable_private_network ? hcloud_server_network.monitoring[*].ip : []
}

output "firewall_id" {
  description = "ID of the monitoring firewall"
  value       = hcloud_firewall.monitoring.id
}

output "firewall_name" {
  description = "Name of the monitoring firewall"
  value       = hcloud_firewall.monitoring.name
}

output "network_id" {
  description = "ID of the private network"
  value       = var.enable_private_network ? hcloud_network.monitoring[0].id : null
}

output "network_name" {
  description = "Name of the private network"
  value       = var.enable_private_network ? hcloud_network.monitoring[0].name : null
}

output "volume_ids" {
  description = "IDs of additional volumes"
  value       = var.disk_size > 0 ? hcloud_volume.monitoring[*].id : []
}

output "mimir_bucket_name" {
  description = "Name of the Mimir S3 bucket"
  value       = try(minio_s3_bucket.mimir[0].bucket, "")
}

output "loki_bucket_name" {
  description = "Name of the Loki S3 bucket"
  value       = try(minio_s3_bucket.loki[0].bucket, "")
}

output "tempo_bucket_name" {
  description = "Name of the Tempo S3 bucket"
  value       = try(minio_s3_bucket.tempo[0].bucket, "")
}

output "backup_bucket_name" {
  description = "Name of the backup S3 bucket"
  value       = try(minio_s3_bucket.backup[0].bucket, "")
}

output "object_storage_endpoint" {
  description = "Hetzner Object Storage endpoint"
  value       = local.s3_storage_endpoint
}

output "object_storage_region" {
  description = "Hetzner Object Storage region"
  value       = var.object_storage_region
}

output "monitoring_ports" {
  description = "Fixed ports used by monitoring services"
  value = {
    wizard       = local.wizard_port
    grafana      = local.grafana_port
    loki         = local.loki_port
    otel_grpc    = local.otel_grpc_port
    otel_http    = local.otel_http_port
    tempo_http   = local.tempo_http_port
    tempo_grpc   = local.tempo_grpc_port
    mimir        = local.mimir_port
    prometheus   = local.prometheus_port
    alertmanager = local.alertmanager_port
  }
}

output "bucket_setup_instructions" {
  description = "Instructions for setting up buckets"
  value = var.enable_object_storage ? [
    "Buckets are created automatically via Terraform using MinIO provider",
    "Configure applications with endpoint: ${local.s3_storage_endpoint}",
    "Use your Hetzner Object Storage credentials for access",
    "Region: ${var.object_storage_region}",
  ] : [
    "Hetzner Object Storage not enabled. Set enable_object_storage = true to enable bucket creation.",
    "You will also need to provide object_storage_access_key and object_storage_secret_key.",
    "Available regions: fsn1, nbg1, hel1",
  ]
}

output "location" {
  description = "Hetzner Cloud location where resources are deployed"
  value       = var.location
}

output "ssh_private_key" {
  description = "Private SSH key for instances (sensitive)"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_public_key" {
  description = "Public SSH key for instances"
  value       = tls_private_key.ssh.public_key_openssh
}

output "ansible_inventory" {
  description = "Ansible Inventory"
  value       = <<-EOT
[monitoring]
%{for idx, server in hcloud_server.monitoring~}
${server.name} ansible_host=${server.ipv4_address} ansible_user=ansible
%{endfor~}

[monitoring:vars]
cloud_environment=hetzner
location=${var.location}
stack=${local.stack_name}
role=${var.role}
mimir_bucket=${local.mimir_bucket}
loki_bucket=${local.loki_bucket}
tempo_bucket=${local.tempo_bucket}
backup_bucket=${local.backup_bucket}
object_storage_endpoint=${local.s3_storage_endpoint}
object_storage_region=${var.object_storage_region}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
}
