output "instance_ids" {
  description = "IDs of monitoring instances"
  value       = try(aws_instance.monitoring[*].id, [])
}

output "instance_private_ips" {
  description = "Private IP addresses of monitoring instances"
  value       = try(aws_instance.monitoring[*].private_ip, [])
}

output "instance_public_ips" {
  description = "Public IP addresses of monitoring instances"
  value       = try(aws_instance.monitoring[*].public_ip, [])
}

output "elastic_ips" {
  description = "Elastic IP addresses"
  value       = try(aws_eip.monitoring[*].public_ip, [])
}

output "security_group_id" {
  description = "ID of the monitoring security group"
  value       = aws_security_group.monitoring.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = try(aws_iam_role.monitoring[0].arn, "")
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = try(aws_iam_instance_profile.monitoring[0].name, var.iam_instance_profile)
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

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = try(aws_lb.monitoring[0].dns_name, "")
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = try(aws_lb.monitoring[0].arn, "")
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = try(aws_lb.monitoring[0].zone_id, "")
}

output "autoscaling_group_name" {
  description = "Name of the auto-scaling group"
  value       = try(aws_autoscaling_group.monitoring[0].name, "")
}

output "autoscaling_group_arn" {
  description = "ARN of the auto-scaling group"
  value       = try(aws_autoscaling_group.monitoring[0].arn, "")
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = try(aws_launch_template.monitoring[0].id, "")
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = try(aws_launch_template.monitoring[0].latest_version, "")
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.monitoring[0].name, "")
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = try(aws_cloudwatch_log_group.monitoring[0].arn, "")
}

output "monitoring_endpoints" {
  description = "Endpoints for monitoring services"
  value = {
    grafana    = var.enable_load_balancer ? (var.acm_certificate_arn != "" ? "https://${try(aws_lb.monitoring[0].dns_name, "")}:443" : "tcp://${try(aws_lb.monitoring[0].dns_name, "")}:443") : ""
    loki       = var.enable_load_balancer ? "http://${try(aws_lb.monitoring[0].dns_name, "")}:3100" : ""
    otel_grpc  = var.enable_load_balancer ? "${try(aws_lb.monitoring[0].dns_name, "")}:4317" : ""
    otel_http  = var.enable_load_balancer ? "http://${try(aws_lb.monitoring[0].dns_name, "")}:4318" : ""
    tempo_http = var.enable_load_balancer ? "http://${try(aws_lb.monitoring[0].dns_name, "")}:3200" : ""
    tempo_grpc = var.enable_load_balancer ? "${try(aws_lb.monitoring[0].dns_name, "")}:9095" : ""
    mimir      = var.enable_load_balancer ? "http://${try(aws_lb.monitoring[0].dns_name, "")}:9009" : ""
  }
}

output "tls_enabled" {
  description = "Whether TLS is enabled on the load balancer"
  value       = var.acm_certificate_arn != ""
}

output "certificate_arn" {
  description = "ARN of the ACM certificate being used"
  value       = var.acm_certificate_arn
}

output "monitoring_ports" {
  description = "Fixed ports used by monitoring services"
  value = {
    grafana      = 443
    loki         = 3100
    otel_grpc    = 4317
    otel_http    = 4318
    tempo_http   = 3200
    tempo_grpc   = 9095
    mimir        = 9009
    prometheus   = 9090
    alertmanager = 9093
  }
}
