terraform {
  required_version = ">= 1.0"

  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.60"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

provider "exoscale" {
  # Credentials are typically set via environment variables:
  # EXOSCALE_API_KEY and EXOSCALE_API_SECRET
}

# AWS provider configured for Exoscale SOS (S3-compatible object storage)
provider "aws" {
  alias = "exoscale_sos"

  # Use Exoscale credentials as AWS credentials
  # Set via environment variables:
  # AWS_ACCESS_KEY_ID (same as EXOSCALE_API_KEY)
  # AWS_SECRET_ACCESS_KEY (same as EXOSCALE_API_SECRET)

  region = var.zone

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true

  endpoints {
    s3 = local.sos_endpoint
  }
}

provider "tls" {
  # Configuration options
}
