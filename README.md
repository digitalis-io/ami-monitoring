<div align="center">

<a href="https://digitalis.io/">
  <img src="https://digitalis-marketplace-assets.s3.us-east-1.amazonaws.com/DigitalisDigital_DigitalisFullLogoGradient+-+medium.png" alt="Digitalis.IO" width="400"/>
</a>

# Digitalis.IO Monitoring Stack

**A complete, production-ready monitoring solution by [Digitalis.IO](https://digitalis.io/)**

Deploy Grafana, Prometheus, Loki, Tempo, Mimir, and Alertmanager to AWS, Hetzner Cloud, or Exoscale with just a few commands.

[![Website](https://img.shields.io/badge/website-digitalis.io-blue)](https://digitalis.io/)
[![Documentation](https://img.shields.io/badge/docs-monitoring--stack-green)](https://digitalis.io/)

</div>

---

## What's Inside

This monitoring stack provides:

- **Grafana**: Beautiful, interactive dashboards for visualizing all your metrics, logs, and traces
- **Prometheus**: Powerful time-series database for collecting and storing metrics
- **Loki**: Efficient log aggregation and querying system inspired by Prometheus
- **Tempo**: Distributed tracing backend for tracking requests across your services
- **Mimir**: Horizontally scalable, long-term storage for Prometheus metrics
- **Alertmanager**: Intelligent alert routing and notification management

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         Grafana                             │
│              (Visualization & Dashboards)                   │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐   ┌────────▼────────┐   ┌───────▼────────┐
│   Prometheus   │   │      Loki       │   │     Tempo      │
│   (Metrics)    │   │     (Logs)      │   │    (Traces)    │
└────────────────┘   └─────────────────┘   └────────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  Long-term Storage │
                    │  (S3/Object Store) │
                    └────────────────────┘
```

### Component Roles

- **Grafana**: Your central dashboard hub - query, visualize, and alert on all your data
- **Prometheus**: Scrapes metrics from your applications and infrastructure every few seconds
- **Loki**: Stores logs efficiently and lets you query them using LogQL (like Prometheus for logs)
- **Tempo**: Captures distributed traces to show you exactly how requests flow through your system
- **Mimir**: Provides virtually unlimited retention for your Prometheus metrics via object storage
- **Alertmanager**: Deduplicates, groups, and routes alerts to the right notification channels

## Quick Start

Choose your deployment method based on your cloud provider and preferred tools:

### AWS Deployments

#### 🚀 CloudFormation (Recommended for AWS)

The easiest way to get started on AWS - no DevOps experience required!

**Deploy in one command:**
```bash
cd cloudformation
./deploy-stack-simple.sh
```

Or click to launch directly in AWS Console:

[![Launch Stack](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png)](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?templateURL=https://cf-templates-436673215683-us-east-1.s3.us-east-1.amazonaws.com/monitoring-stack-simple.yaml)

**Features:**
- Auto-detects your default VPC and subnet
- Creates EC2 instances with all monitoring services
- Optional S3 buckets for long-term storage
- Simple web-based configuration wizard
- Complete in 5-10 minutes

📖 **[Full CloudFormation Guide](./cloudformation/README.md)** - Step-by-step instructions, troubleshooting, cost estimates, and more

#### ⚙️ Terraform for AWS

For infrastructure-as-code enthusiasts or existing Terraform users:

```bash
cd terraform/aws
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your VPC and subnet IDs
terraform init
terraform apply
```

**Features:**
- Full control over all configuration options
- Auto-scaling groups for high availability
- Network load balancer support
- CloudWatch integration for Grafana
- Comprehensive IAM role management

📖 **[Terraform AWS Guide](./terraform/README.md#aws-deployment-guide)** - Configuration examples, variables reference, and advanced setups

---

### Hetzner Cloud

Deploy to European cloud infrastructure with excellent price/performance:

```bash
cd terraform/hetzner
export HCLOUD_TOKEN="your-hetzner-token"
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferences
terraform init
terraform apply
```

**Features:**
- Native Hetzner Object Storage integration
- Private networking between instances
- Placement groups for high availability
- Auto-generated SSH keys
- Cost-effective pricing (~€8-50/month)

📖 **[Terraform Hetzner Guide](./terraform/README.md#hetzner-cloud-deployment-guide)** - Server types, locations, object storage setup

---

### Exoscale

Deploy on Swiss infrastructure with a focus on security and privacy:

```bash
cd terraform/exoscale
export EXOSCALE_API_KEY="your-api-key"
export EXOSCALE_API_SECRET="your-secret-key"
terraform init
terraform apply
```

📖 **[Terraform Exoscale Guide](./terraform/README.md#exoscale-deployment-guide)** - Zone selection, instance types, and configuration

---

## Detailed Documentation

### Deployment Guides

| Guide | Description | Best For |
|-------|-------------|----------|
| **[CloudFormation Deployment](./cloudformation/README.md)** | AWS-native infrastructure deployment with step-by-step instructions | AWS users, beginners, quick deployments |
| **[Terraform - General Guide](./terraform/README.md)** | Multi-cloud Terraform deployment covering AWS, Hetzner, and Exoscale | Infrastructure-as-code users, multi-cloud deployments |
| **[Terraform AWS Module](./terraform/aws/README.md)** | Technical reference for integrating the AWS module into your Terraform projects | Advanced Terraform users, module integration |
| **[Terraform Hetzner Module](./terraform/hetzner/README.md)** | Technical reference for the Hetzner Cloud Terraform module | Hetzner users, cost-conscious deployments |

### Post-Deployment

After your infrastructure is deployed, you need to configure the monitoring stack:

#### Option 1: Configuration Wizard (Recommended)

1. Find your server IP from the deployment outputs
2. Open your browser to `https://YOUR-SERVER-IP:9443`
3. Follow the wizard to configure all services
4. Access Grafana at `https://YOUR-SERVER-IP`

#### Option 2: Manual Configuration

If you prefer command-line configuration, you can use Ansible or Docker Compose to deploy the monitoring services to your infrastructure.

### Service Endpoints

After deployment, services are accessible on these ports:

| Service | Port | URL Example | Default Credentials |
|---------|------|-------------|---------------------|
| **Configuration Wizard** | 9443 | `https://your-ip:9443` | None |
| **Grafana** | 443 | `https://your-ip` | admin / admin |
| **Prometheus** | 9090 | `http://your-ip:9090` | None |
| **Loki** | 3100 | `http://your-ip:3100` | None |
| **Alertmanager** | 9093 | `http://your-ip:9093` | None |
| **Mimir** | 9009 | `http://your-ip:9009` | None |
| **Tempo** | 3200 | `http://your-ip:3200` | None |
| **OpenTelemetry** | 4317/4318 | `http://your-ip:4317` (gRPC) / `4318` (HTTP) | None |

⚠️ **Security Note**: Change the default Grafana password immediately after first login!

## Examples

### Example 1: Quick Test Environment (AWS CloudFormation)

Deploy a minimal stack for testing in under 5 minutes:

```bash
cd cloudformation
INSTANCE_TYPE=t3.small STACK_NAME=test-monitoring ./deploy-stack-simple.sh
```

**Result**: Single t3.small instance (~$15/month) with all monitoring services

### Example 2: Production Setup (AWS Terraform)

High-availability deployment with auto-scaling:

```hcl
module "monitoring" {
  source = "git@bitbucket.org:digitalisio/ap-monitoring-stack.git//terraform/aws"

  region     = "us-east-1"
  vpc_id     = "vpc-123456"
  subnet_ids = ["subnet-abc", "subnet-def", "subnet-xyz"]

  # Auto-scaling: 2-6 instances based on load
  enable_auto_scaling = true
  min_size           = 2
  max_size           = 6
  desired_capacity   = 3
  instance_type      = "t3.large"

  # Load balancer for HA
  enable_load_balancer = true

  # S3 storage for long-term retention
  enable_mimir_bucket  = true
  enable_loki_bucket   = true
  enable_tempo_bucket  = true
  enable_backup_bucket = true

  # CloudWatch integration
  enable_cloudwatch_datasource = true

  # Restrict access to office network
  allowed_external_cidrs = ["203.0.113.0/24"]

  tags = {
    Environment = "Production"
    Team        = "DevOps"
  }
}
```

**Result**: Enterprise-ready monitoring with HA, auto-scaling, and CloudWatch dashboards

### Example 3: Cost-Optimized Hetzner Deployment

Deploy on Hetzner Cloud for excellent price/performance:

```bash
cd terraform/hetzner
export HCLOUD_TOKEN="your-token"

cat > terraform.tfvars <<EOF
project_name = "monitoring"
location     = "hel1"
server_type  = "cx32"
instance_count = 2

enable_private_network = true
enable_object_storage  = true
object_storage_region  = "fsn1"

enable_mimir_bucket = true
enable_loki_bucket  = true

allowed_external_cidrs = ["YOUR.IP.HERE/32"]
EOF

terraform init && terraform apply
```

**Result**: 2-server monitoring cluster (~€40/month) with private networking and object storage

### Example 4: Single-Server Development (AWS)

Minimal setup for development or personal use:

```bash
cd cloudformation
INSTANCE_TYPE=t3.medium \
AWS_KEY_NAME=my-key \
LOKI_BUCKET=dev-logs-$(date +%s) \
STACK_NAME=dev-monitoring \
./deploy-stack-simple.sh
```

**Result**: Single t3.medium instance (~$30/month) with Loki log storage

## Common Use Cases

### Monitoring Kubernetes Clusters

1. Deploy the monitoring stack in your cloud provider
2. Install Prometheus exporters in your K8s cluster
3. Configure Prometheus to scrape your cluster endpoints
4. Import Kubernetes dashboards into Grafana
5. Set up alerts for pod failures, high memory, etc.

### Application Performance Monitoring (APM)

1. Deploy the stack with Tempo enabled
2. Instrument your application with OpenTelemetry
3. Send traces to `http://your-ip:4317` (gRPC) or `:4318` (HTTP)
4. Visualize traces in Grafana's Explore view
5. Create dashboards showing request latency, error rates, etc.

### Centralized Log Aggregation

1. Deploy with Loki S3/object storage enabled
2. Install Promtail on your servers or use fluentd/fluent-bit
3. Configure log shippers to send to `http://your-ip:3100`
4. Query logs in Grafana using LogQL
5. Create alerts based on log patterns

### Infrastructure Monitoring

1. Deploy the stack using the CloudFormation or Terraform guides
2. Install node_exporter on all servers you want to monitor
3. Configure Prometheus scrape configs for your exporters
4. Import pre-built dashboards (Node Exporter Full, AWS CloudWatch, etc.)
5. Set up alerts for disk space, CPU, memory thresholds

## Cost Estimates

### AWS

| Configuration | Instance Type | Monthly Cost (estimate) |
|---------------|---------------|-------------------------|
| Testing | 1x t3.small | ~$25 |
| Small Production | 1x t3.medium + S3 | ~$50 |
| Medium Production | 1x t3.large + S3 + EBS | ~$100 |
| HA Production | 3x t3.large + NLB + S3 | ~$250 |

### Hetzner Cloud

| Configuration | Server Type | Monthly Cost (estimate) |
|---------------|-------------|-------------------------|
| Testing | 1x cx22 | ~€8 |
| Small Production | 1x cx32 + Object Storage | ~€20 |
| HA Production | 3x cx32 + Object Storage | ~€50 |

### Exoscale

| Configuration | Instance Type | Monthly Cost (estimate) |
|---------------|---------------|-------------------------|
| Testing | 1x standard.medium | ~CHF 40 |
| Small Production | 1x standard.large + SOS | ~CHF 80 |
| HA Production | 3x standard.large + SOS | ~CHF 250 |

*Costs vary by region, storage usage, and data transfer. Check your cloud provider for exact pricing.*

## Security Best Practices

1. **Change default passwords**: Update Grafana admin password immediately
2. **Restrict network access**: Use `allowed_external_cidrs` to limit access to trusted IPs
3. **Use HTTPS**: All services support TLS - configure certificates for production
4. **Enable S3 encryption**: Enabled by default in Terraform modules
5. **Regular updates**: Keep monitoring software up-to-date
6. **IAM roles**: Use cloud provider IAM roles instead of access keys where possible
7. **Network isolation**: Deploy in private subnets with bastion hosts for production

## Troubleshooting

### Can't access services after deployment

1. **Check security groups/firewall**: Ensure your IP is in `allowed_external_cidrs`
2. **Wait for services to start**: Give it 5-10 minutes after deployment
3. **Verify instance is running**: Check your cloud provider console
4. **Use HTTPS for Grafana**: Try `https://` instead of `http://`

### Services are slow or crashing

1. **Increase instance size**: Move to a larger instance type
2. **Add more instances**: Enable auto-scaling or increase instance_count
3. **Enable S3/object storage**: Move data to object storage to reduce local disk usage
4. **Check logs**: SSH to instances and check service logs

### Bucket creation fails

**Error**: "Bucket name already exists"

**Solution**: S3 bucket names must be globally unique. Either:
- Remove custom bucket name variables (auto-generates unique names)
- Choose more unique names like `company-mimir-$(date +%s)`

### Deployment stuck or times out

1. **Check quota limits**: You may have hit cloud provider limits
2. **Verify credentials**: Ensure API keys/credentials are valid
3. **Check VPC/networking**: Ensure VPC has internet gateway (for public deployments)
4. **Review CloudFormation/Terraform events**: Look for specific error messages

## Support and Contributing

### Getting Help

- **Documentation Issues**: Check the deployment guide for your platform
- **CloudFormation Errors**: Review the Events tab in AWS CloudFormation console
- **Terraform Errors**: Run `terraform plan` to see what will change before applying
- **Service Issues**: SSH to instances and check logs in `/var/log/`

### Contributing

Improvements and bug fixes are welcome! Please:

1. Test changes in a non-production environment
2. Update relevant documentation
3. Submit detailed pull requests
4. Follow existing code style and patterns

## About Digitalis.IO

<div align="center">

<a href="https://digitalis.io/">
  <img src="https://digitalis-marketplace-assets.s3.us-east-1.amazonaws.com/DigitalisDigital_DigitalisFullLogoGradient+-+medium.png" alt="Digitalis.IO" width="300"/>
</a>

</div>

[**Digitalis.IO**](https://digitalis.io/) specializes in cloud infrastructure, DevOps automation, and observability solutions. We help organizations build, deploy, and monitor modern cloud-native applications with best-in-class open-source tools.

**Our Services:**
- ☁️ Cloud Infrastructure Design & Migration
- 🔧 DevOps & Platform Engineering
- 📊 Observability & Monitoring Solutions
- 🚀 Kubernetes & Container Orchestration
- 🔒 Security & Compliance

**Learn More:**
- 🌐 Visit our website: [digitalis.io](https://digitalis.io/)
- 📧 Contact us for consulting and support
- 💼 Enterprise support packages available

## License

This project is part of the Digitalis.IO monitoring stack. See the LICENSE file for details.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Any use of third-party trademarks or logos are subject to those third-party's policies.

**Third-party products and services used in this project:**
- **Grafana®** - Grafana Labs
- **Prometheus®** - Cloud Native Computing Foundation (CNCF)
- **Loki™** - Grafana Labs
- **Tempo™** - Grafana Labs
- **Mimir™** - Grafana Labs
- **Alertmanager** - Prometheus project
- **Amazon Web Services (AWS)®** - Amazon.com, Inc.
- **Hetzner Cloud™** - Hetzner Online GmbH
- **Exoscale™** - Exoscale
- **Terraform®** - HashiCorp, Inc.
- **CloudFormation™** - Amazon Web Services, Inc.

## What's Next

### Coming Soon

- **Google Cloud Platform** support
- **Azure** support
- **Kubernetes Helm charts** for container-native deployments
- **Pre-configured dashboards** for common services
- **Backup and restore** automation

### After Deployment

1. **Import dashboards**: Browse https://grafana.com/grafana/dashboards/
2. **Configure data sources**: Set up Prometheus, Loki, and Tempo in Grafana
3. **Set up alerts**: Create alert rules in Prometheus/Alertmanager
4. **Configure notifications**: Add Slack, PagerDuty, email channels
5. **Secure your installation**: Change passwords, restrict access, enable TLS

---

<div align="center">

**Ready to get started?** Choose your deployment method above and follow the guide! 🚀

<br>

Made with ❤️ by [**Digitalis.IO**](https://digitalis.io/)

</div>
