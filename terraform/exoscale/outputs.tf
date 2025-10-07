output "instance_ids" {
  description = "IDs of monitoring instances"
  value       = exoscale_compute_instance.monitoring[*].id
}

output "instance_names" {
  description = "Names of monitoring instances"
  value       = exoscale_compute_instance.monitoring[*].name
}

output "instance_public_ips" {
  description = "Public IP addresses of monitoring instances"
  value       = exoscale_compute_instance.monitoring[*].public_ip_address
}

output "instance_private_ips" {
  description = "Private IP addresses of monitoring instances (if using private network)"
  value       = [for instance in exoscale_compute_instance.monitoring : try(instance.private_network_ip_address, "")]
}

output "instance_ipv6_addresses" {
  description = "IPv6 addresses of monitoring instances"
  value       = var.enable_ipv6 ? exoscale_compute_instance.monitoring[*].ipv6_address : []
}

output "security_group_id" {
  description = "ID of the monitoring security group"
  value       = exoscale_security_group.monitoring.id
}

output "security_group_name" {
  description = "Name of the monitoring security group"
  value       = exoscale_security_group.monitoring.name
}

output "mimir_bucket_name" {
  description = "Name of the Mimir S3 bucket"
  value       = try(aws_s3_bucket.mimir[0].id, "")
}

output "mimir_bucket_arn" {
  description = "ARN of the Mimir S3 bucket"
  value       = try(aws_s3_bucket.mimir[0].arn, "")
}

output "loki_bucket_name" {
  description = "Name of the Loki S3 bucket"
  value       = try(aws_s3_bucket.loki[0].id, "")
}

output "loki_bucket_arn" {
  description = "ARN of the Loki S3 bucket"
  value       = try(aws_s3_bucket.loki[0].arn, "")
}

output "tempo_bucket_name" {
  description = "Name of the Tempo S3 bucket"
  value       = try(aws_s3_bucket.tempo[0].id, "")
}

output "tempo_bucket_arn" {
  description = "ARN of the Tempo S3 bucket"
  value       = try(aws_s3_bucket.tempo[0].arn, "")
}

output "backup_bucket_name" {
  description = "Name of the backup S3 bucket"
  value       = try(aws_s3_bucket.backup[0].id, "")
}

output "backup_bucket_arn" {
  description = "ARN of the backup S3 bucket"
  value       = try(aws_s3_bucket.backup[0].arn, "")
}

output "sos_endpoint" {
  description = "SOS endpoint for the zone"
  value       = local.sos_endpoint
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
  value = [
    "Buckets are created automatically via Terraform using AWS S3 provider",
    "Configure applications with endpoint: ${local.sos_endpoint}",
    "Use your Exoscale API credentials for S3 access",
  ]
}

output "zone" {
  description = "Exoscale zone where resources are deployed"
  value       = var.zone
}

output "template_id" {
  description = "ID of the template used for instances"
  value       = data.exoscale_template.ubuntu.id
}

output "template_name" {
  description = "Name of the template used for instances"
  value       = data.exoscale_template.ubuntu.name
}

output "ansible_inventory" {
  description = "Ansible Inventory"
  value       = <<-EOT
[monitoring]
%{for idx, instance in exoscale_compute_instance.monitoring~}
${instance.name} ansible_host=${instance.public_ip_address} ansible_user=ansible
%{endfor~}

[monitoring:vars]
cloud_environment=exoscale
zone=${var.zone}
stack=${local.stack_name}
role=${var.role}
mimir_bucket=${local.mimir_bucket}
loki_bucket=${local.loki_bucket}
tempo_bucket=${local.tempo_bucket}
backup_bucket=${local.backup_bucket}
sos_endpoint=${local.sos_endpoint}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
}
