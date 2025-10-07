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

variable "location" {
  description = "Hetzner Cloud location (e.g., nbg1, fsn1, hel1, ash, hil)"
  type        = string
  default     = "hel1"
}

variable "instance_count" {
  description = "Number of monitoring instances"
  type        = number
  default     = 1
}

variable "server_type" {
  description = "Hetzner Cloud server type (e.g., cx21, cx31, cx41, cx51, ccx13, ccx23, ccx33)"
  type        = string
  default     = "cx22"
}

variable "disk_size" {
  description = "Size of additional volume in GB (0 means no additional volume)"
  type        = number
  default     = 100
}

variable "ssh_key_name" {
  description = "Name of SSH key to use for instances (if empty, will create new key)"
  type        = string
  default     = ""
}

variable "image_name" {
  description = "Name of the OS image (if empty, will use Ubuntu 22.04)"
  type        = string
  default     = "ubuntu-22.04"
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

variable "enable_object_storage" {
  description = "Enable Hetzner Object Storage for buckets"
  type        = bool
  default     = false
}

variable "object_storage_region" {
  description = "Hetzner Object Storage region (fsn1, nbg1, hel1)"
  type        = string
  default     = "fsn1"
}

variable "object_storage_access_key" {
  description = "Hetzner Object Storage access key (can also be set via MINIO_ACCESS_KEY env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "object_storage_secret_key" {
  description = "Hetzner Object Storage secret key (can also be set via MINIO_SECRET_KEY env var)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_external_cidrs" {
  description = "External CIDR blocks allowed to access the monitoring stack (empty list means only instances within firewall)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Labels to apply to all resources"
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

variable "enable_private_network" {
  description = "Create and attach instances to a private network"
  type        = bool
  default     = false
}

variable "private_network_subnet" {
  description = "Subnet for private network in CIDR notation"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_placement_group" {
  description = "Create placement group for spreading instances across physical hosts"
  type        = bool
  default     = false
}
