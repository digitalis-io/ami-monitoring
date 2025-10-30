variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "dm"
}

variable "role" {
  description = "Role tag for resources"
  type        = string
  default     = "digitalis-monitoring"

}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of existing subnet IDs for instances"
  type        = list(string)
}

variable "lb_subnet_ids" {
  description = "List of existing subnet IDs for load balancer (if different from subnet_ids)"
  type        = list(string)
  default     = []
}

variable "instance_count" {
  description = "Number of monitoring instances"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Size of data volume in GB"
  type        = number
  default     = 50
}

variable "key_pair_name" {
  description = "Name of SSH key pair"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for the EC2 Monitoring Stack"
  type        = string
  default     = ""
}

variable "enable_load_balancer" {
  description = "Enable Network Load Balancer"
  type        = bool
  default     = false
}

variable "load_balancer_internal" {
  description = "Make load balancer internal"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for TLS on load balancer (optional)"
  type        = string
  default     = ""
}

variable "enable_mimir_bucket" {
  description = "Create S3 bucket for Mimir storage"
  type        = bool
  default     = false
}

variable "mimir_bucket_name" {
  description = "Name of S3 bucket for Mimir (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "enable_loki_bucket" {
  description = "Create S3 bucket for Loki storage"
  type        = bool
  default     = false
}

variable "loki_bucket_name" {
  description = "Name of S3 bucket for Loki (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "enable_tempo_bucket" {
  description = "Create S3 bucket for Tempo storage"
  type        = bool
  default     = false
}

variable "tempo_bucket_name" {
  description = "Name of S3 bucket for Tempo (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "enable_backup_bucket" {
  description = "Create S3 bucket for backups"
  type        = bool
  default     = false
}

variable "backup_bucket_name" {
  description = "Name of S3 bucket for backups (if empty, auto-generated)"
  type        = string
  default     = ""
}

variable "bucket_force_destroy" {
  description = "Force destroy S3 buckets on terraform destroy"
  type        = bool
  default     = false
}

variable "bucket_versioning" {
  description = "Enable versioning on S3 buckets"
  type        = bool
  default     = true
}

variable "bucket_encryption" {
  description = "Enable encryption on S3 buckets"
  type        = bool
  default     = true
}

variable "allowed_external_cidrs" {
  description = "External CIDR blocks allowed to access the monitoring stack (empty list means VPC only)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for instances"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_datasource" {
  description = "Enable IAM permissions for Grafana CloudWatch datasource"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 30
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling group"
  type        = bool
  default     = false
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "enable_eip" {
  description = "Attach Elastic IP to instances"
  type        = bool
  default     = false
}

variable "vpc_cidr" {
  description = "VPC CIDR block for internal security group rules"
  type        = string
  default     = "" # If empty, will be fetched from VPC data source
}

variable "user_data_script" {
  description = "Custom user data script"
  type        = string
  default     = ""
}

variable "iam_instance_profile" {
  description = "IAM instance profile name (if empty, will create one)"
  type        = string
  default     = ""
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager access"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "enable_termination_protection" {
  description = "Enable termination protection"
  type        = bool
  default     = false
}

variable "internal_ports" {
  description = "List of internal ports to open between instances"
  type        = list(number)
  default     = [22, 3000, 5432, 7946, 7947, 3100, 9090, 3200, 4317, 4318, 443]
}
