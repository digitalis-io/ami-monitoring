# Deploying the Monitoring Stack with Terraform

This guide will help you deploy the Digitalis.IO monitoring stack to your cloud provider using Terraform. Don't worry if you're new to DevOps - we'll walk through everything step by step!

## What is This?

This Terraform configuration automatically creates all the cloud resources you need to run a complete monitoring solution, including:

- **Grafana**: Beautiful dashboards to visualize your data
- **Prometheus**: Collects and stores metrics from your systems
- **Loki**: Aggregates and searches through your logs
- **Tempo**: Tracks requests across your applications (distributed tracing)
- **Mimir**: Long-term storage for metrics
- **Alertmanager**: Sends notifications when something goes wrong

## What is Terraform?

Terraform is a tool that creates cloud infrastructure automatically. Instead of clicking through your cloud provider's website to create servers, storage, and networks, you write a simple configuration file and Terraform creates everything for you.

---

## Table of Contents

1. [Supported Cloud Providers](#supported-cloud-providers)
2. [Before You Start](#before-you-start)
3. [AWS Deployment Guide](#aws-deployment-guide)
4. [Hetzner Cloud Deployment Guide](#hetzner-cloud-deployment-guide)
5. [Exoscale Deployment Guide](#exoscale-deployment-guide)
6. [After Deployment](#after-deployment)
7. [Understanding Your Configuration](#understanding-your-configuration)
8. [Common Issues and Solutions](#common-issues-and-solutions)
9. [Cleaning Up (Removing Everything)](#cleaning-up-removing-everything)

---

## Supported Cloud Providers

✅ **AWS** (Amazon Web Services) - Full support with auto-scaling and load balancing
✅ **Hetzner Cloud** - European cloud provider with great pricing
✅ **Exoscale** - Swiss cloud provider focused on security and privacy
🚧 **Google Cloud** and **Azure** - Coming soon!

---

## Before You Start

### What You'll Need

1. **Terraform Installed** on your computer
   - Download from: https://www.terraform.io/downloads
   - After installing, verify by opening a terminal and typing: `terraform version`

2. **Cloud Provider Account**
   - Create an account with your chosen provider (AWS, Hetzner, or Exoscale)
   - You'll need your account credentials (API keys or access keys)

3. **A Text Editor**
   - Notepad++ (Windows), TextEdit (Mac), or VS Code work great

4. **About 30 Minutes** to complete the setup

### Basic Terraform Commands

You'll use these four commands throughout this guide:

```bash
# 1. Initialize Terraform (downloads required plugins)
terraform init

# 2. See what Terraform will create (preview)
terraform plan

# 3. Create the infrastructure
terraform apply

# 4. Remove everything
terraform destroy
```

---

## AWS Deployment Guide

### Step 1: Get Your AWS Credentials

1. Log into the AWS Console (https://console.aws.amazon.com)
2. Go to **Services** → **IAM** → **Users**
3. Click **Add User**, give it a name like "terraform"
4. Select **Programmatic Access**
5. Attach the **AdministratorAccess** policy (for simplicity)
6. Save the **Access Key ID** and **Secret Access Key** somewhere safe

### Step 2: Find Your VPC and Subnet Information

The monitoring stack needs to run inside a VPC (Virtual Private Cloud). You probably already have one:

1. Go to **Services** → **VPC** → **Your VPCs**
2. Copy the **VPC ID** (looks like `vpc-0123456789abcdef0`)
3. Click on **Subnets** in the left menu
4. Copy at least **two Subnet IDs** from different availability zones

**VPC Requirements**

For internet-facing Load Balancer:
- VPC must have an Internet Gateway attached
- Route Table with 0.0.0.0/0 → Internet Gateway
- Public subnets associated with this Route Table

For internal Load Balancer (private subnets only):
- Set variable `load_balancer_internal = true` (default is `false`)
- No Internet Gateway required
- Use private subnets only

### Step 3: Configure Your Credentials

**Option A: Environment Variables (Recommended)**
```bash
export AWS_ACCESS_KEY_ID="your-access-key-here"
export AWS_SECRET_ACCESS_KEY="your-secret-key-here"
export AWS_DEFAULT_REGION="us-east-1"
```

**Option B: AWS CLI Configuration**
```bash
aws configure
# Follow the prompts to enter your credentials
```

### Step 4: Create Your Configuration File

1. Navigate to the `terraform/aws` directory:
   ```bash
   cd terraform/aws
   ```

2. Create a file named `terraform.tfvars` (copy from the example):
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your favorite text editor:

**Minimal Configuration (simplest setup):**
```hcl
# Replace these with your actual values
region     = "us-east-1"
vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-abc123", "subnet-def456"]

# This creates 1 server of medium size
instance_count = 1
instance_type  = "t3.medium"

# Create storage buckets for your monitoring data
enable_mimir_bucket  = true
enable_loki_bucket   = true
enable_tempo_bucket  = true
enable_backup_bucket = true

# Basic project info
project_name = "my-monitoring"
environment  = "production"

tags = {
  Project = "Monitoring"
  Owner   = "your-name"
}
```

**Production Configuration (recommended for real use):**
```hcl
region     = "us-east-1"
vpc_id     = "vpc-0123456789abcdef0"
subnet_ids = ["subnet-abc123", "subnet-def456"]

# Auto-scaling: automatically adds/removes servers based on load
enable_auto_scaling = true
min_size            = 2  # Always keep at least 2 servers
max_size            = 6  # Never create more than 6 servers
desired_capacity    = 3  # Start with 3 servers
instance_type       = "t3.large"  # Larger servers for production

# Load balancer: distributes traffic across your servers
enable_load_balancer   = true
load_balancer_internal = false  # Set to true if only accessed from within AWS

# Storage configuration
enable_mimir_bucket  = true
enable_loki_bucket   = true
enable_tempo_bucket  = true
enable_backup_bucket = true
bucket_versioning    = true  # Keep old versions of your data
bucket_encryption    = true  # Encrypt data at rest

# Monitoring features
enable_monitoring            = true  # Detailed CloudWatch metrics
enable_cloudwatch_logs       = true  # Send logs to CloudWatch
enable_cloudwatch_datasource = true  # View CloudWatch data in Grafana
cloudwatch_retention_days    = 90    # Keep logs for 90 days

# Security: Allow access from specific IP addresses
# Leave empty for VPC-only access
allowed_external_cidrs = ["203.0.113.10/32"]  # Replace with YOUR IP

# SSH access (optional, for troubleshooting)
# key_pair_name = "my-key-pair"

# Safety features
enable_termination_protection = true  # Prevent accidental deletion

tags = {
  Project     = "Monitoring"
  Team        = "DevOps"
  Environment = "Production"
}
```

**Using as a Terraform Module (referencing from Git):**

If you want to use this monitoring stack as a module in your own Terraform project:

```hcl
module "monitoring_stack" {
  source     = "git@bitbucket.org:digitalisio/ap-monitoring-stack.git//terraform/aws"
  region     = "us-east-1"
  vpc_id     = "vpc-b287b3d5"
  subnet_ids = ["subnet-1609f14d", "subnet-7909bc30", "subnet-8ef89ceb"]
  ami_id     = "ami-0520d2aad6b9f5e14"

  # Optional: Custom bucket names (auto-generated if not specified)
  mimir_bucket_name  = "dm-serg-mimir-bucket"
  loki_bucket_name   = "dm-serg-loki-bucket"
  tempo_bucket_name  = "dm-serg-tempo-bucket"
  backup_bucket_name = "dm-serg-backup-bucket"

  # S3 Bucket Configuration
  bucket_versioning    = false
  bucket_encryption    = false
  bucket_force_destroy = false

  # This creates 1 server of medium size
  instance_count = 1
  instance_type  = "t3.medium"

  # Create storage buckets for your monitoring data
  enable_mimir_bucket  = true
  enable_loki_bucket   = true
  enable_tempo_bucket  = true
  enable_backup_bucket = true

  # Basic project info
  project_name = "serg"
  environment  = "dev"

  tags = {
    Project = "Monitoring"
    Owner   = "serg"
  }
}

# Access module outputs
output "monitoring_instance_ids" {
  value = module.monitoring_stack.instance_ids
}

output "monitoring_grafana_url" {
  value = module.monitoring_stack.monitoring_endpoints["grafana"]
}
```

Then run:
```bash
terraform init
terraform plan
terraform apply
```

### Step 5: Deploy!

```bash
# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create everything (you'll be asked to confirm)
terraform apply
```

Type `yes` when prompted. Terraform will now create:
- EC2 instances (virtual servers)
- S3 buckets (storage)
- Security groups (firewalls)
- Load balancer (optional)
- IAM roles (permissions)

This takes about 5-10 minutes.

### Step 6: Access Your Monitoring Stack

After deployment completes, Terraform will show you important information:

```
Outputs:

instance_ids = ["i-abc123", "i-def456"]
instance_private_ips = ["10.0.1.10", "10.0.2.20"]
load_balancer_dns = "my-monitoring-lb-123456.us-east-1.elb.amazonaws.com"
monitoring_endpoints = {
  "grafana" = "https://my-monitoring-lb-123456.us-east-1.elb.amazonaws.com"
}
```

**If you enabled a load balancer:**
- Open your browser and go to the `load_balancer_dns` address
- Example: `https://my-monitoring-lb-123456.us-east-1.elb.amazonaws.com`

**If you didn't enable a load balancer:**
- You'll need to connect to one of the instance IPs
- This typically requires SSH access or AWS Systems Manager

---

## Hetzner Cloud Deployment Guide

Hetzner Cloud is a European cloud provider known for excellent pricing and performance. Perfect for smaller deployments!

### Step 1: Get Your Hetzner API Token

1. Log into Hetzner Cloud Console: https://console.hetzner.cloud
2. Select your project (or create a new one)
3. Go to **Security** → **API Tokens**
4. Click **Generate API Token**
5. Give it a name like "terraform"
6. Select **Read & Write** permissions
7. Copy and save the token somewhere safe (you won't see it again!)

### Step 2: Configure Your Credentials

Set your API token as an environment variable:

```bash
# On Linux/Mac:
export HCLOUD_TOKEN="your-token-here"

# On Windows (PowerShell):
$env:HCLOUD_TOKEN="your-token-here"
```

### Step 3: Create Your Configuration File

1. Navigate to the `terraform/hetzner` directory:
   ```bash
   cd terraform/hetzner
   ```

2. Create `terraform.tfvars`:

**Basic Configuration:**
```hcl
# Project settings
project_name = "my-monitoring"
environment  = "prod"

# Server location
# Options: nbg1 (Nuremberg), fsn1 (Falkenstein), hel1 (Helsinki),
#          ash (Ashburn, USA), hil (Hillsboro, USA)
location = "hel1"

# Create 1 server
instance_count = 1
server_type    = "cx22"  # 2 CPU, 4GB RAM - good starting point
disk_size      = 100     # Additional storage in GB

# Storage buckets (uses Hetzner Object Storage)
enable_object_storage    = true
object_storage_region    = "fsn1"
enable_mimir_bucket      = true
enable_loki_bucket       = true
enable_tempo_bucket      = true

# Access control - allow connections from anywhere
# Replace with your IP for better security: "YOUR.IP.ADDRESS.HERE/32"
allowed_external_cidrs = ["0.0.0.0/0"]

tags = {
  project = "monitoring"
  owner   = "your-name"
}
```

**Production Configuration:**
```hcl
project_name = "my-monitoring"
environment  = "prod"
location     = "hel1"

# Multiple servers for high availability
instance_count = 3
server_type    = "cx32"  # 4 CPU, 8GB RAM
disk_size      = 200     # More storage

# Spread servers across physical hosts
enable_placement_group = true

# Private networking between servers
enable_private_network   = true
private_network_subnet   = "10.0.0.0/16"

# Object storage
enable_object_storage    = true
object_storage_region    = "fsn1"
enable_mimir_bucket      = true
enable_loki_bucket       = true
enable_tempo_bucket      = true
enable_backup_bucket     = true

# Security - restrict to your office IP
allowed_external_cidrs = ["203.0.113.0/24"]

# IPv6 support
enable_ipv6 = true

tags = {
  project     = "monitoring"
  environment = "production"
  team        = "devops"
}
```

### Step 4: Set Up Object Storage (Optional but Recommended)

If you enabled object storage, you need credentials:

1. In Hetzner Console, go to **Object Storage**
2. Create credentials (Access Key and Secret Key)
3. Set them as environment variables:

```bash
export MINIO_ACCESS_KEY="your-access-key"
export MINIO_SECRET_KEY="your-secret-key"
```

Or add them to `terraform.tfvars`:
```hcl
object_storage_access_key = "your-access-key"  # Not recommended for security
object_storage_secret_key = "your-secret-key"
```

### Step 5: Deploy!

```bash
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted. Deployment takes about 3-5 minutes.

### Step 6: Access Your Servers

Terraform will output your server information:

```
Outputs:

server_ips = ["1.2.3.4", "5.6.7.8"]
server_names = ["my-monitoring-prod-1", "my-monitoring-prod-2"]
```

Access Grafana by visiting: `https://1.2.3.4` (use the first server IP)

**Default SSH access:**
Terraform automatically creates an SSH key for you. Find it in the outputs:
```bash
terraform output -raw ssh_private_key > monitoring_key.pem
chmod 600 monitoring_key.pem
ssh -i monitoring_key.pem root@1.2.3.4
```

---

## Exoscale Deployment Guide

Exoscale is a Swiss cloud provider with a focus on security, privacy, and simplicity.

### Step 1: Get Your Exoscale API Credentials

1. Log into Exoscale Portal: https://portal.exoscale.com
2. Go to **IAM** → **API Keys**
3. Click **Add Key**
4. Select **Unrestricted** (or create a custom role with compute and storage permissions)
5. Save your **API Key** and **Secret Key**

### Step 2: Configure Your Credentials

```bash
# On Linux/Mac:
export EXOSCALE_API_KEY="your-api-key"
export EXOSCALE_API_SECRET="your-secret-key"

# On Windows (PowerShell):
$env:EXOSCALE_API_KEY="your-api-key"
$env:EXOSCALE_API_SECRET="your-secret-key"
```

### Step 3: Create Your Configuration File

1. Navigate to the `terraform/exoscale` directory:
   ```bash
   cd terraform/exoscale
   ```

2. Create `terraform.tfvars`:

**Basic Configuration:**
```hcl
# Project settings
project_name = "my-monitoring"
environment  = "prod"

# Zone selection
# Options: ch-gva-2 (Geneva), ch-dk-2 (Zurich), at-vie-1 (Vienna),
#          de-fra-1 (Frankfurt), de-muc-1 (Munich), bg-sof-1 (Sofia)
zone = "ch-gva-2"

# Create 1 instance
instance_count = 1
instance_type  = "standard.medium"  # 2 CPU, 4GB RAM
disk_size      = 100                # Root disk in GB

# Storage buckets (uses Exoscale Object Storage - SOS)
enable_mimir_bucket  = true
enable_loki_bucket   = true
enable_tempo_bucket  = true

# Access control - allow from anywhere
# Replace "0.0.0.0/0" with your IP for better security
allowed_external_cidrs = ["0.0.0.0/0"]

tags = {
  project = "monitoring"
  owner   = "your-name"
}
```

**Production Configuration:**
```hcl
project_name = "my-monitoring"
environment  = "prod"
zone         = "ch-gva-2"

# Multiple instances for redundancy
instance_count = 3
instance_type  = "standard.large"  # 4 CPU, 8GB RAM
disk_size      = 200

# Storage
enable_mimir_bucket  = true
enable_loki_bucket   = true
enable_tempo_bucket  = true
enable_backup_bucket = true

# Prevent accidental bucket deletion
bucket_force_destroy = false

# Security - only allow your office network
allowed_external_cidrs = ["203.0.113.0/24"]

# IPv6 support
enable_ipv6 = true

tags = {
  project     = "monitoring"
  environment = "production"
  team        = "devops"
  compliance  = "gdpr"
}
```

### Step 4: Deploy!

```bash
terraform init
terraform plan
terraform apply
```

Type `yes` to confirm. Deployment takes about 5-10 minutes.

### Step 5: Access Your Infrastructure

Terraform outputs your instance information:

```
Outputs:

instance_ips = ["185.19.28.10", "185.19.28.11"]
instance_names = ["my-monitoring-prod-1", "my-monitoring-prod-2"]
```

Access Grafana at: `https://185.19.28.10`

---

## After Deployment

### What Happens Next?

Terraform has created the infrastructure (servers, storage, networking), but the monitoring software needs to be installed. You have two options:

#### Option 1: Use the Configuration Wizard (Recommended)

The deployment includes a web-based configuration wizard:

1. Find your server IP from Terraform outputs
2. Open your browser and go to: `https://YOUR-SERVER-IP:9443`
3. Follow the wizard to configure your monitoring stack
4. The wizard will generate configuration and deploy everything

#### Option 2: Manual Deployment with Ansible

If you're comfortable with command-line tools:

1. SSH into your server
2. Clone this repository
3. Run the Ansible playbook (see main README.md for details)

### Default Credentials

Once deployed, access Grafana with:
- **Username**: `admin`
- **Password**: `admin` (you'll be prompted to change this on first login)

### Monitoring Service Ports

All services are accessible on these ports:

| Service | Port | URL Example |
|---------|------|-------------|
| Grafana | 443 | https://your-server-ip |
| Configuration Wizard | 9443 | https://your-server-ip:9443 |
| Prometheus | 9090 | http://your-server-ip:9090 |
| Loki | 3100 | http://your-server-ip:3100 |
| Alertmanager | 9093 | http://your-server-ip:9093 |
| Mimir | 9009 | http://your-server-ip:9009 |
| Tempo | 3200 | http://your-server-ip:3200 |

---

## Understanding Your Configuration

### Common Variables Explained

#### `instance_count` vs `enable_auto_scaling`

- **Fixed instances** (`instance_count = 2`): Always runs exactly 2 servers
- **Auto-scaling** (`enable_auto_scaling = true`): Automatically adds servers when busy, removes when idle

Use fixed instances for predictable costs, auto-scaling for variable workloads.

#### Storage Buckets

Each monitoring component can store data in object storage (S3 or equivalent):

- **Mimir bucket**: Long-term metrics storage (months to years)
- **Loki bucket**: Long-term log storage
- **Tempo bucket**: Distributed tracing data
- **Backup bucket**: Configuration and data backups

You can enable/disable each one independently:
```hcl
enable_mimir_bucket = true   # Enable
enable_loki_bucket  = false  # Disable
```

#### Security: `allowed_external_cidrs`

This controls who can access your monitoring stack from the internet:

```hcl
# Allow from anywhere (not recommended for production)
allowed_external_cidrs = ["0.0.0.0/0"]

# Allow only from your office
allowed_external_cidrs = ["203.0.113.0/24"]

# Allow from multiple locations
allowed_external_cidrs = ["203.0.113.0/24", "198.51.100.50/32"]

# VPC/internal access only
allowed_external_cidrs = []
```

**How to find your IP:** Visit https://whatismyip.com

#### Instance/Server Types

**AWS:**
- `t3.medium` - 2 CPU, 4GB RAM (testing)
- `t3.large` - 2 CPU, 8GB RAM (small production)
- `t3.xlarge` - 4 CPU, 16GB RAM (medium production)
- `m5.xlarge` - 4 CPU, 16GB RAM (production)

**Hetzner:**
- `cx22` - 2 CPU, 4GB RAM (testing)
- `cx32` - 4 CPU, 8GB RAM (small production)
- `cx42` - 8 CPU, 16GB RAM (medium production)
- `cx52` - 16 CPU, 32GB RAM (large production)

**Exoscale:**
- `standard.medium` - 2 CPU, 4GB RAM (testing)
- `standard.large` - 4 CPU, 8GB RAM (small production)
- `standard.xlarge` - 8 CPU, 16GB RAM (medium production)
- `standard.huge` - 16 CPU, 32GB RAM (large production)

#### Tags/Labels

Tags help organize and track your resources:

```hcl
tags = {
  Project     = "Monitoring"       # What is this for?
  Environment = "Production"        # Prod, dev, staging?
  Team        = "DevOps"           # Who owns it?
  CostCenter  = "Engineering"      # Who pays for it?
  Owner       = "john@company.com" # Who to contact?
}
```

---

## Common Issues and Solutions

### Problem: "Error: VPC not found"

**Solution:** Double-check your VPC ID. Go to AWS Console → VPC → Your VPCs and copy the exact ID.

### Problem: "Error: No valid credential sources found"

**Solution:** Your cloud provider credentials aren't set. Review Step 2 of your provider's guide and ensure environment variables are set correctly.

### Problem: "Error: Insufficient IAM permissions"

**Solution:** Your API key/user needs more permissions. Ensure it has rights to create EC2 instances, S3 buckets, security groups, etc.

### Problem: "Error: Subnet not found"

**Solution:** Make sure your subnet IDs are correct and in the same VPC you specified.

### Problem: Can't access Grafana after deployment

**Solutions:**
1. Check your `allowed_external_cidrs` includes your IP address
2. Wait 5 minutes - services take time to start
3. Verify the server is running: `terraform show | grep instance_id`
4. Check if you need to use `https://` instead of `http://`

### Problem: "Error: creating S3 bucket: BucketAlreadyExists"

**Solution:** S3 bucket names must be globally unique. Either:
1. Let Terraform auto-generate names (remove `mimir_bucket_name` etc.)
2. Choose more unique custom names

### Problem: Terraform is stuck on "Creating..."

**Solutions:**
1. Wait - large deployments can take 10-15 minutes
2. Check your cloud provider's console to see if resources are being created
3. If truly stuck (30+ minutes), press Ctrl+C and run `terraform apply` again

### Problem: "Error: Quota exceeded"

**Solution:** You've hit your cloud provider's limits. Either:
1. Request a quota increase from your provider
2. Reduce `instance_count` or use smaller instance types
3. Deploy in a different region

---

## Cleaning Up (Removing Everything)

When you no longer need the monitoring stack, remove all resources:

```bash
# Preview what will be deleted
terraform plan -destroy

# Delete everything
terraform destroy
```

Type `yes` when prompted.

**⚠️ Warning:** This permanently deletes:
- All servers/instances
- All storage buckets and their data
- Load balancers
- Security groups
- Everything Terraform created

**Before destroying:**
1. Backup any important data from Grafana
2. Export any dashboards you want to keep
3. Save alert configurations

**If you have `bucket_force_destroy = false`:**
Terraform will fail to delete buckets that contain data. This is a safety feature. To proceed:

1. Manually empty the buckets in your cloud console
2. Run `terraform destroy` again

OR

1. Change to `bucket_force_destroy = true` in `terraform.tfvars`
2. Run `terraform apply` (updates the configuration)
3. Run `terraform destroy`

---

## Cost Estimates

### AWS
- **Basic Setup** (1x t3.medium, 3 small S3 buckets): ~$30-40/month
- **Production Setup** (3x t3.large, load balancer, 4 S3 buckets): ~$200-250/month

### Hetzner Cloud
- **Basic Setup** (1x cx22, object storage): ~€8-10/month
- **Production Setup** (3x cx32, object storage): ~€40-50/month

### Exoscale
- **Basic Setup** (1x standard.medium, SOS storage): ~CHF 40-50/month
- **Production Setup** (3x standard.large, SOS storage): ~CHF 200-250/month

*Costs vary based on data transfer, storage usage, and region. These are estimates.*

---

## Next Steps

### Learn More About Terraform
- Official tutorials: https://learn.hashicorp.com/terraform
- Documentation: https://www.terraform.io/docs

### Configure Your Monitoring Stack
- See the main README.md in the project root
- Explore the Ansible playbook for customization
- Import pre-built Grafana dashboards

### Get Help
- Check the project documentation
- Review Terraform's error messages carefully - they're usually helpful
- Consult your cloud provider's documentation

---

## Quick Reference Card

**Essential Commands:**
```bash
terraform init      # Set up Terraform (run once)
terraform plan      # Preview changes
terraform apply     # Make changes
terraform destroy   # Delete everything
terraform output    # Show outputs again
terraform show      # Show current state
```

**Environment Variables:**

*AWS:*
```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

*Hetzner:*
```bash
export HCLOUD_TOKEN="..."
export MINIO_ACCESS_KEY="..."  # For object storage
export MINIO_SECRET_KEY="..."
```

*Exoscale:*
```bash
export EXOSCALE_API_KEY="..."
export EXOSCALE_API_SECRET="..."
```

**Important Files:**
- `terraform.tfvars` - Your configuration (don't commit to git!)
- `terraform.tfstate` - Current infrastructure state (don't edit!)
- `*.tf` - Terraform code (read-only unless you know what you're doing)

---

## Support

For issues specific to:
- **Terraform usage**: Review this guide and check https://www.terraform.io/docs
- **Cloud provider issues**: Contact your provider's support
- **Monitoring stack software**: See the main project README.md

Remember: Terraform is just creating the infrastructure. The monitoring software itself is configured separately through Ansible or the configuration wizard.

---

**Happy Monitoring! 🎉**
