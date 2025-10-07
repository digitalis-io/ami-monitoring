# Hetzner Cloud Module for Digitalis.IO Monitoring Stack

This Terraform module deploys the Digitalis.IO monitoring stack infrastructure on Hetzner Cloud.

## Features

- **Compute Instances**: Deploy multiple Hetzner Cloud servers with configurable types
- **Storage Volumes**: Optional additional volumes for data persistence
- **Hetzner Object Storage**: Native integration with Hetzner's S3-compatible object storage
- **Private Networking**: Optional private network for instance communication
- **Placement Groups**: Spread instances across physical hosts for high availability
- **Firewall**: Automatic firewall configuration with customizable rules
- **SSH Key Management**: Auto-generated or existing SSH key support
- **IPv6 Support**: Optional IPv6 addressing

## Prerequisites

- Terraform >= 1.0
- Hetzner Cloud account and API token
- (Optional) Hetzner Object Storage credentials for bucket creation

## Quick Start

1. **Set Hetzner Cloud credentials**:
```bash
export HCLOUD_TOKEN="your-hetzner-cloud-api-token"
```

2. **Configure Hetzner Object Storage** (optional):
```bash
export MINIO_ACCESS_KEY="your-hetzner-object-storage-access-key"
export MINIO_SECRET_KEY="your-hetzner-object-storage-secret-key"
```

3. **Initialize Terraform**:
```bash
terraform init
```

4. **Create configuration file**:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
```

5. **Plan and apply**:
```bash
terraform plan
terraform apply
```

## Server Types

Hetzner Cloud offers various server types:

| Type | vCPUs | RAM | Disk | Network | Price/month* |
|------|-------|-----|------|---------|--------------|
| cx21 | 2 | 4 GB | 40 GB | 20 TB | ~€5 |
| cx31 | 2 | 8 GB | 80 GB | 20 TB | ~€10 |
| cx41 | 4 | 16 GB | 160 GB | 20 TB | ~€20 |
| cx51 | 8 | 32 GB | 240 GB | 20 TB | ~€40 |
| ccx13 | 2 | 8 GB | 80 GB | 20 TB | ~€13 |
| ccx23 | 4 | 16 GB | 160 GB | 20 TB | ~€26 |
| ccx33 | 8 | 32 GB | 240 GB | 20 TB | ~€52 |

*Prices are approximate and may vary by region

## Locations

Available Hetzner Cloud locations:

- **nbg1** - Nuremberg, Germany
- **fsn1** - Falkenstein, Germany
- **hel1** - Helsinki, Finland
- **ash** - Ashburn, VA, USA
- **hil** - Hillsboro, OR, USA

## Hetzner Object Storage

This module natively supports Hetzner Object Storage using the MinIO Terraform provider.

### Configuration

```hcl
# Enable Hetzner Object Storage
enable_object_storage = true

# Select region (fsn1, nbg1, hel1)
object_storage_region = "fsn1"

# Provide credentials (or use environment variables)
object_storage_access_key = "your-access-key"
object_storage_secret_key = "your-secret-key"

# Enable buckets as needed
enable_mimir_bucket  = true
enable_loki_bucket   = true
enable_tempo_bucket  = true
enable_backup_bucket = true
```

### Available Regions

- **fsn1** - Falkenstein, Germany
- **nbg1** - Nuremberg, Germany
- **hel1** - Helsinki, Finland

### Endpoint Format

Buckets are accessible at: `https://{region}.your-objectstorage.com/{bucket-name}`

Example: `https://fsn1.your-objectstorage.com/my-mimir-bucket`

### No Object Storage

```hcl
enable_object_storage = false
enable_mimir_bucket   = false
enable_loki_bucket    = false
enable_tempo_bucket   = false
enable_backup_bucket  = false
```

## Fixed Service Ports

The following ports are standardized across all deployments:

| Service | Port | Protocol |
|---------|------|----------|
| Wizard | 9443 | HTTPS |
| Grafana | 443 | HTTPS |
| Loki | 3100 | HTTP |
| OpenTelemetry gRPC | 4317 | gRPC |
| OpenTelemetry HTTP | 4318 | HTTP |
| Tempo HTTP | 3200 | HTTP |
| Tempo gRPC | 9095 | gRPC |
| Mimir | 9009 | HTTP |
| Prometheus | 9090 | HTTP |
| Alertmanager | 9093 | HTTP |

## Security

### Firewall Configuration

By default, the firewall allows:
- All traffic between instances in the same firewall
- ICMP (ping)
- External access based on `allowed_external_cidrs`

### SSH Access

The module automatically:
- Creates an SSH key pair (or uses existing key)
- Configures an `ansible` user with sudo access
- Sets up SSH key authentication

### External Access

Control external access via `allowed_external_cidrs`:

```hcl
# Open to all (default)
allowed_external_cidrs = ["0.0.0.0/0"]

# Restrict to specific IPs
allowed_external_cidrs = ["203.0.113.10/32", "198.51.100.0/24"]

# Block all external access (instances only)
allowed_external_cidrs = []
```

## High Availability

### Placement Groups

Enable placement groups to distribute instances across physical hosts:

```hcl
enable_placement_group = true
instance_count         = 3
```

### Private Network

Create a private network for secure inter-instance communication:

```hcl
enable_private_network = true
private_network_subnet = "10.0.0.0/16"
```

## Usage Examples

### Basic Single Server

```hcl
module "monitoring" {
  source = "./hetzner"

  location     = "nbg1"
  server_type  = "cx31"
  instance_count = 1
}
```

### High Availability Setup

```hcl
module "monitoring" {
  source = "./hetzner"

  location       = "fsn1"
  server_type    = "cx41"
  instance_count = 3

  enable_placement_group = true
  enable_private_network = true

  # Hetzner Object Storage
  enable_object_storage     = true
  object_storage_region     = "fsn1"
  object_storage_access_key = "your-access-key"
  object_storage_secret_key = "your-secret-key"

  enable_mimir_bucket  = true
  enable_loki_bucket   = true
  enable_tempo_bucket  = true
  enable_backup_bucket = true

  disk_size = 200

  tags = {
    Environment = "Production"
    Team        = "DevOps"
  }
}
```

### Development Environment

```hcl
module "monitoring_dev" {
  source = "./hetzner"

  location     = "nbg1"
  server_type  = "cx21"
  environment  = "dev"

  enable_mimir_bucket  = false
  enable_loki_bucket   = false
  enable_tempo_bucket  = false
  enable_backup_bucket = false

  bucket_force_destroy = true
  disk_size            = 50

  tags = {
    Environment = "Development"
  }
}
```

## Outputs

The module provides comprehensive outputs:

- `server_ids` - Server IDs
- `server_names` - Server names
- `server_public_ipv4` - Public IPv4 addresses
- `server_public_ipv6` - Public IPv6 addresses (if enabled)
- `server_private_ips` - Private IP addresses (if using private network)
- `firewall_id` - Firewall ID
- `network_id` - Private network ID (if enabled)
- `volume_ids` - Additional volume IDs
- `*_bucket_name` - S3 bucket names
- `s3_endpoint` - S3 endpoint URL
- `monitoring_ports` - Fixed service ports
- `ansible_inventory` - Ready-to-use Ansible inventory
- `ssh_private_key` - SSH private key (sensitive)
- `ssh_public_key` - SSH public key

## Post-Deployment

After deployment:

1. **Get server IPs**:
```bash
terraform output server_public_ipv4
```

2. **Get Ansible inventory**:
```bash
terraform output -raw ansible_inventory > inventory/hetzner.yaml
```

3. **Get SSH key**:
```bash
terraform output -raw ssh_private_key > ~/.ssh/monitoring-key
chmod 600 ~/.ssh/monitoring-key
```

4. **Connect to server**:
```bash
ssh -i ~/.ssh/monitoring-key ansible@<server-ip>
```

5. **Deploy monitoring stack**:
```bash
cd /path/to/ansible-playbook
ansible-playbook -i inventory/hetzner.yaml deploy-prometheus.yml
```

## Costs

Estimated monthly costs:

### Single Server
- **cx31**: ~€10/month
- **100GB volume**: ~€5/month
- **Total**: ~€15/month

### HA Setup (3 servers)
- **3x cx41**: ~€60/month
- **3x 200GB volumes**: ~€30/month
- **Total**: ~€90/month

*Excludes S3 storage costs which vary by provider*

## Troubleshooting

### Quota Errors

Hetzner Cloud has default limits. Request increases via support if needed:
- Default: 10 servers per project
- Default: 5TB additional volumes

### Network Errors

If instances can't communicate:
1. Check firewall rules
2. Verify private network attachment
3. Check security group membership

### Volume Mount Issues

If volumes don't mount:
1. Check cloud-init logs: `cat /var/log/cloud-init-output.log`
2. Verify volume attachment: `lsblk`
3. Check mount script: `cat /var/log/auto-mount.log`

## Contributing

Improvements and bug fixes are welcome. Please submit pull requests to the main repository.

## License

This module is part of the Digitalis.IO Monitoring Stack project.
