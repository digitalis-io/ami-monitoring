# AWS Terraform Module for Digitalis.IO Monitoring Stack

This Terraform module deploys the Digitalis.IO monitoring stack on AWS with highly customizable configuration options.

## Features

- EC2 instances or Auto Scaling Groups for the monitoring stack
- Optional Network Load Balancer for high availability
- S3 buckets for Mimir, Loki, Tempo, and backups
- Security groups with configurable ports
- IAM roles and policies for S3 access
- CloudWatch logging integration
- Support for existing VPC and subnets

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- Existing VPC and subnets

## Usage

### Basic Example

```hcl
module "monitoring_stack" {
  source = "./aws"

  project_name = "my-monitoring"
  environment  = "production"
  region       = "us-east-1"

  # Use existing infrastructure
  vpc_id     = "vpc-123456"
  subnet_ids = ["subnet-abc123", "subnet-def456"]

  # Instance configuration
  instance_count   = 2
  instance_type    = "t3.large"
  key_pair_name    = "my-key-pair"

  # Enable S3 buckets
  enable_mimir_bucket  = true
  enable_loki_bucket   = true
  enable_tempo_bucket  = true
  enable_backup_bucket = true

  # Enable load balancer
  enable_load_balancer = true

  tags = {
    Team = "DevOps"
    Cost = "Monitoring"
  }
}
```

### Advanced Example with Auto Scaling

```hcl
module "monitoring_stack" {
  source = "./aws"

  project_name = "digitalis-monitoring"
  environment  = "prod"
  region       = "eu-west-1"

  # Existing infrastructure
  vpc_id        = var.vpc_id
  subnet_ids    = var.private_subnet_ids
  lb_subnet_ids = var.public_subnet_ids  # Different subnets for LB

  # Auto-scaling configuration
  enable_auto_scaling = true
  min_size            = 2
  max_size            = 6
  desired_capacity    = 3
  instance_type       = "m5.xlarge"

  # Storage configuration
  root_volume_size = 100
  data_volume_size = 500

  # Enable all S3 buckets with custom names
  enable_mimir_bucket = true
  mimir_bucket_name   = "my-custom-mimir-bucket"

  enable_loki_bucket = true
  loki_bucket_name   = "my-custom-loki-bucket"

  enable_tempo_bucket = true
  tempo_bucket_name   = "my-custom-tempo-bucket"

  enable_backup_bucket = true
  backup_bucket_name   = "my-custom-backup-bucket"

  # S3 bucket settings
  bucket_versioning    = true
  bucket_encryption    = true
  bucket_force_destroy = false

  # Network Load Balancer
  enable_load_balancer   = true
  load_balancer_internal = true

  # Security - allow external access from specific CIDRs
  allowed_external_cidrs = ["203.0.113.0/24"]  # Example external CIDR

  # Monitoring and logging
  enable_monitoring      = true
  enable_cloudwatch_logs = true
  cloudwatch_retention_days = 90
  enable_cloudwatch_datasource = true  # Grafana CloudWatch permissions

  # Systems Manager access
  enable_ssm = true

  # Protection
  enable_termination_protection = true

  tags = {
    Project     = "Monitoring"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Using Existing IAM Profile

```hcl
module "monitoring_stack" {
  source = "./aws"

  project_name = "monitoring"
  environment  = "dev"
  region       = "us-west-2"

  vpc_id     = data.aws_vpc.existing.id
  subnet_ids = data.aws_subnets.private.ids

  instance_count = 1
  instance_type  = "t3.medium"

  # Use existing IAM instance profile
  iam_instance_profile = "my-existing-profile"

  # Custom AMI
  ami_id = "ami-0123456789abcdef0"

  # Custom user data script
  user_data_script = file("${path.module}/custom_user_data.sh")
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `region` | AWS region | `string` |
| `vpc_id` | Existing VPC ID | `string` |
| `subnet_ids` | List of existing subnet IDs for instances | `list(string)` |

### Optional Variables

See [variables.tf](variables.tf) for a complete list of configurable options including:

- Instance configuration (type, count, volumes)
- Auto-scaling settings
- Load balancer configuration
- S3 bucket settings
- Security group rules
- Port configurations
- IAM settings
- CloudWatch logging
- Tags

## Outputs

| Name | Description |
|------|-------------|
| `instance_ids` | IDs of monitoring instances |
| `instance_private_ips` | Private IP addresses of instances |
| `security_group_id` | ID of the monitoring security group |
| `load_balancer_dns` | DNS name of the load balancer |
| `mimir_bucket_name` | Name of the Mimir S3 bucket |
| `loki_bucket_name` | Name of the Loki S3 bucket |
| `tempo_bucket_name` | Name of the Tempo S3 bucket |
| `backup_bucket_name` | Name of the backup S3 bucket |
| `monitoring_endpoints` | Map of service endpoints |

## Security Considerations

- All instances are placed in private subnets by default
- Security groups allow all traffic within VPC by default
- External access can be configured via `allowed_external_cidrs` variable
- S3 buckets are encrypted by default
- IAM roles follow least privilege principle
- Support for Systems Manager (SSM) for secure access
- Optional CloudWatch datasource permissions for Grafana dashboards

## Port Configuration

Fixed ports (not configurable):

- **443**: Grafana (HTTPS)
- **3100**: Loki
- **4317**: OpenTelemetry gRPC
- **4318**: OpenTelemetry HTTP
- **3200**: Tempo HTTP
- **9095**: Tempo gRPC
- **9009**: Mimir
- **9090**: Prometheus (internal)
- **9093**: Alertmanager (internal)

## Post-Deployment Steps

1. SSH into instances or use Systems Manager Session Manager
2. Deploy the monitoring stack using Ansible or Docker Compose
3. Configure data sources in Grafana
   - CloudWatch datasource will have IAM permissions if `enable_cloudwatch_datasource` is true
   - EC2 tags and regions are always accessible for discovery
4. Set up alert rules and notification channels
5. Configure backup strategies for persistent data

## IAM Permissions

The module creates IAM roles with the following permissions:

### Always Included
- EC2: DescribeTags, DescribeInstances, DescribeRegions (for instance discovery)
- S3: Access to configured buckets (Mimir, Loki, Tempo, Backup)

### Optional (based on variables)
- CloudWatch: Full read access for metrics and logs (when `enable_cloudwatch_datasource = true`)
- CloudWatch Logs: Agent permissions (when `enable_cloudwatch_logs = true`)
- Systems Manager: Session Manager access (when `enable_ssm = true`)

## Troubleshooting

### Instance Access
- Ensure key pair is correctly specified
- Check security group rules allow your IP
- Use Systems Manager Session Manager if enabled

### Load Balancer
- Verify health checks are passing
- Check target group attachments
- Ensure instances are in healthy state

### S3 Buckets
- Verify IAM role has correct permissions
- Check bucket policies if using custom names
- Ensure region consistency

## License

See LICENSE file in the repository root.
