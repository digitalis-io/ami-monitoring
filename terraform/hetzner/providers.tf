terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    minio = {
      source  = "aminueza/minio"
      version = "~> 3.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}

provider "hcloud" {
  # Credentials are typically set via environment variables:
  # HCLOUD_TOKEN
}

# MinIO provider configured for Hetzner Object Storage
# Requires Hetzner Object Storage credentials
provider "minio" {
  # Server endpoint format: {location}.your-objectstorage.com
  # Example: fsn1.your-objectstorage.com
  minio_server = "${var.object_storage_region}.your-objectstorage.com"

  # Set via environment variables or variables:
  # MINIO_ACCESS_KEY or var.object_storage_access_key
  # MINIO_SECRET_KEY or var.object_storage_secret_key
  minio_user     = var.object_storage_access_key
  minio_password = var.object_storage_secret_key

  # Region should match Hetzner location (fsn1, nbg1, hel1)
  minio_region = var.object_storage_region

  # SSL enabled for Hetzner Object Storage
  minio_ssl = true
}

provider "tls" {
  # Configuration options
}
