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

variable "zone" {
  description = "Exoscale zone (e.g., ch-gva-2, ch-dk-2, at-vie-1, de-fra-1, de-muc-1, bg-sof-1)"
  type        = string
  default     = "ch-gva-2"
}

variable "instance_count" {
  description = "Number of monitoring instances"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "Exoscale instance type (e.g., standard.medium, standard.large, standard.xlarge)"
  type        = string
  default     = "standard.medium"
}

variable "disk_size" {
  description = "Size of root disk in GB"
  type        = number
  default     = 100
}

variable "ssh_key_name" {
  description = "Name of SSH key to use for instances"
  type        = string
  default     = ""
}

variable "template_name" {
  description = "Name of the template/image (if empty, will use Ubuntu 22.04)"
  type        = string
  default     = "Linux Ubuntu 22.04 LTS 64-bit"
}

variable "template_id" {
  description = "Use this template"
  type        = string
  default     = null
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

variable "allowed_external_cidrs" {
  description = "External CIDR blocks allowed to access the monitoring stack (empty list means only instances within security group)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "user_data_script" {
  description = "Custom user data script (cloud-init)"
  type        = string
  default     = ""
}

variable "enable_ipv6" {
  description = "Enable IPv6 on instances"
  type        = bool
  default     = false
}

variable "anti_affinity_group_id" {
  description = "Anti-affinity group ID for spreading instances across physical hosts"
  type        = string
  default     = ""
}

variable "private_network_id" {
  description = "Private network ID to attach instances to"
  type        = string
  default     = ""
}
