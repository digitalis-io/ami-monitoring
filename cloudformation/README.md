# AWS CloudFormation Deployment Guide

Deploy the Digitalis.IO monitoring stack to AWS using CloudFormation. This guide covers everything from basics to production deployment - no DevOps experience required!

[![Launch in AWS](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png 'Launch in AWS')](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/create/review?templateURL=https://cf-templates-436673215683-us-east-1.s3.us-east-1.amazonaws.com/monitoring-stack-simple.yaml)

## What You'll Deploy

This CloudFormation template automatically creates all the AWS resources you need to run a complete monitoring solution:

- **Grafana**: Beautiful dashboards to visualize your data
- **Prometheus**: Collects and stores metrics from your systems
- **Loki**: Aggregates and searches through your logs
- **Tempo**: Tracks requests across your applications (distributed tracing)
- **Mimir**: Long-term storage for metrics
- **Alertmanager**: Sends notifications when something goes wrong

## What is CloudFormation?

CloudFormation is AWS's service that creates cloud infrastructure automatically. Instead of clicking through the AWS Console to create servers, storage, and networks, you write a template file and CloudFormation creates everything for you. It's like a recipe for your infrastructure!

**Why use CloudFormation?**
- AWS-native solution (no external tools needed)
- Easier integration with AWS services
- No state files to manage
- Built-in rollback if something goes wrong
- Free to use (you only pay for the resources created)

---

## Table of Contents

1. [Before You Start](#before-you-start)
2. [Available Templates](#available-templates)
3. [Quick Start: Simple Deployment](#quick-start-simple-deployment)
4. [Advanced: Full Stack Deployment](#advanced-full-stack-deployment)
5. [Deploying via AWS Console](#deploying-via-aws-console-no-command-line)
6. [Configuration Reference](#configuration-reference)
7. [After Deployment](#after-deployment)
8. [Updating Your Stack](#updating-your-stack)
9. [Troubleshooting](#troubleshooting)
10. [Cost Estimates](#cost-estimates)
11. [Cleanup](#cleanup)

---

## Before You Start

### Prerequisites

1. **AWS Account** - Sign up at https://aws.amazon.com
2. **AWS CLI** (optional, for command-line deployment) - Download from https://aws.amazon.com/cli/
3. **AWS Credentials** (for CLI):
   ```bash
   aws configure
   # Enter your Access Key ID, Secret Access Key, and region
   ```
4. **15-30 minutes** for deployment

### What You Should Know

- **VPC (Virtual Private Cloud)**: Your private network in AWS. Most accounts have a default VPC.
- **Subnet**: A section of your VPC. Instances are launched in subnets.
- **Security Group**: Virtual firewall controlling access to your instances.
- **EC2**: AWS virtual servers where the monitoring stack runs.
- **S3**: Object storage for long-term data retention.

---

## Available Templates

### 1. Simple Stack (`monitoring-stack-simple.yaml`) ⭐ Recommended

**Perfect for:**
- Getting started quickly
- Testing and development
- Small deployments
- Learning the monitoring stack

**Features:**
- Single EC2 instance with all services
- Auto-detects default VPC/subnet (zero networking config!)
- Optional S3 storage backends
- Minimal configuration required
- Deployment time: 5-10 minutes

### 2. Full Stack (`monitoring-stack.yaml`)

**Perfect for:**
- Production environments
- High-traffic applications
- High availability requirements
- Multiple teams

**Features:**
- Multiple EC2 instances with auto-scaling
- Network Load Balancer
- Advanced networking configuration
- Production-ready features
- Deployment time: 15-30 minutes

### Comparison Table

| Feature | Simple Stack | Full Stack |
|---------|--------------|------------|
| **Use Case** | Development, Testing, Small deployments | Production, High-traffic environments |
| **Configuration** | Minimal (works with defaults) | Requires VPC/Subnet configuration |
| **Instances** | Single EC2 | Multiple with auto-scaling |
| **Load Balancer** | No | Yes (optional) |
| **High Availability** | No | Yes |
| **Setup Time** | 5-10 minutes | 15-30 minutes |
| **Complexity** | Low | Medium-High |
| **Monthly Cost** | ~$30-100 | ~$150-500 |

---

## Quick Start: Simple Deployment

The Simple Stack is the easiest way to get started. It works with default AWS settings and requires minimal configuration.

### Method 1: One-Command Deployment (Easiest!)

```bash
# Navigate to the cloudformation directory
cd cloudformation

# Deploy with all defaults (uses default VPC, creates 1 t3.medium instance)
./deploy-stack-simple.sh
```

That's it! The script will:
1. Find your default VPC automatically
2. Create a t3.medium EC2 instance
3. Set up all monitoring services
4. Configure security groups
5. Show you how to access your services

**Wait 5-10 minutes** for deployment to complete.

### Method 2: Custom Configuration

Customize your deployment with environment variables:

```bash
# Deploy with a larger instance and SSH access
INSTANCE_TYPE=t3.large AWS_KEY_NAME=my-keypair ./deploy-stack-simple.sh

# Deploy with S3 storage for data persistence
MIMIR_BUCKET=my-metrics-bucket LOKI_BUCKET=my-logs-bucket ./deploy-stack-simple.sh

# Deploy in a different AWS region
AWS_REGION=eu-west-1 ./deploy-stack-simple.sh

# Deploy with a specific VPC and subnet
AWS_VPC=vpc-123456 AWS_SUBNET=subnet-abc123 ./deploy-stack-simple.sh

# Restrict access to your office IP only
EXTERNAL_CIDRS="203.0.113.10/32" ./deploy-stack-simple.sh

# Custom stack name
STACK_NAME=my-monitoring ./deploy-stack-simple.sh
```

### Method 3: See All Options

```bash
./deploy-stack-simple.sh --help
```

### Example Configurations

**Testing Setup (Minimal Cost):**
```bash
INSTANCE_TYPE=t3.small \
STACK_NAME=test-monitoring \
./deploy-stack-simple.sh
```

**Development Setup:**
```bash
INSTANCE_TYPE=t3.medium \
AWS_KEY_NAME=my-key \
LOKI_BUCKET=dev-logs-bucket \
STACK_NAME=dev-monitoring \
./deploy-stack-simple.sh
```

**Production-Ready Single Instance:**
```bash
INSTANCE_TYPE=t3.xlarge \
AWS_KEY_NAME=prod-key \
MIMIR_BUCKET=prod-metrics-bucket \
LOKI_BUCKET=prod-logs-bucket \
TEMPO_BUCKET=prod-traces-bucket \
BACKUP_BUCKET=prod-backups-bucket \
EXTERNAL_CIDRS="203.0.113.0/24" \
STACK_NAME=prod-monitoring \
./deploy-stack-simple.sh
```

---

## Advanced: Full Stack Deployment

The Full Stack template provides high availability and production features.

### Prerequisites

You need to know your VPC and Subnet IDs:

**Finding Your VPC ID:**
1. Go to AWS Console → VPC
2. Click "Your VPCs"
3. Copy the VPC ID (looks like `vpc-0123456789abcdef0`)

**Finding Your Subnet IDs:**
1. Go to AWS Console → VPC → Subnets
2. Copy at least **two subnet IDs** from **different availability zones**
3. Format: `subnet-abc123,subnet-def456` (comma-separated, no spaces)

### Deploy the Full Stack

```bash
# Set your VPC and subnets
export AWS_VPC=vpc-0123456789abcdef0
export AWS_SUBNETS=subnet-abc123,subnet-def456

# Deploy
./deploy-stack.sh
```

### Full Stack Features

- **Auto-Scaling**: Automatically add/remove servers based on load
- **Load Balancer**: Distribute traffic across multiple instances
- **High Availability**: Servers in multiple availability zones
- **Advanced Monitoring**: CloudWatch integration
- **Elastic IPs**: Fixed IP addresses for your instances

---

## Deploying via AWS Console (No Command Line)

Don't want to use the command line? Deploy through the AWS web interface!

### Step 1: Upload Template to S3

1. Go to **AWS Console** → **S3**
2. Create a bucket (or use existing): `my-cloudformation-templates`
3. Upload `monitoring-stack-simple.yaml` to the bucket
4. Click the uploaded file and copy the **Object URL**

### Step 2: Create Stack in CloudFormation

1. Go to **AWS Console** → **CloudFormation**
2. Click **Create Stack** → **With new resources**
3. Choose **Template is ready**
4. Choose **Amazon S3 URL** and paste the Object URL
5. Click **Next**

### Step 3: Configure Stack

**Stack Name:** `monitoring-stack-simple`

**Key Parameters to Configure:**

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| **VpcId** | Leave empty to use default VPC | `vpc-123456` (optional) |
| **SubnetId** | Leave empty to use default subnet | `subnet-abc123` (optional) |
| **InstanceType** | Server size | `t3.medium` |
| **KeyPairName** | SSH key for access | `my-keypair` (optional) |
| **AllowedExternalCidrs** | Who can access (comma-separated) | `203.0.113.10/32` |
| **CreateLokiBucket** | Create log storage bucket | `true` or `false` |
| **CreateMimirBucket** | Create metrics storage bucket | `true` or `false` |

Click **Next**

### Step 4: Configure Stack Options

**Tags (optional but recommended):**
- Key: `Project`, Value: `Monitoring`
- Key: `Environment`, Value: `Production`
- Key: `Owner`, Value: `your-name`

Click **Next**

### Step 5: Review and Create

1. Review all settings
2. Check the box: **"I acknowledge that AWS CloudFormation might create IAM resources"**
3. Click **Create Stack**

### Step 6: Monitor Progress

1. Watch the **Events** tab to see resources being created
2. Status will change from `CREATE_IN_PROGRESS` to `CREATE_COMPLETE`
3. Takes about 5-10 minutes

### Step 7: Get Your Endpoints

1. Click the **Outputs** tab
2. Copy the URLs to access Grafana and other services

---

## Configuration Reference

### Environment Variables (Simple Stack)

**Core Configuration:**

| Variable | Default | Description |
|----------|---------|-------------|
| `STACK_NAME` | `monitoring-stack-simple` | CloudFormation stack name |
| `AWS_REGION` | `us-east-1` | AWS region for deployment |
| `INSTANCE_TYPE` | `t3.medium` | EC2 instance type |
| `AWS_VPC` | (auto-detected) | VPC ID (leave empty for default VPC) |
| `AWS_SUBNET` | (auto-detected) | Subnet ID (leave empty for default) |
| `AWS_KEY_NAME` | (none) | SSH key pair name (optional) |
| `AWS_AMI` | (latest Ubuntu) | Custom AMI ID (optional) |
| `EXTERNAL_CIDRS` | `0.0.0.0/0` | IP addresses allowed access |

**Storage Configuration:**

| Variable | Default | Description |
|----------|---------|-------------|
| `MIMIR_BUCKET` | (none) | S3 bucket for Mimir metrics |
| `LOKI_BUCKET` | (none) | S3 bucket for Loki logs |
| `TEMPO_BUCKET` | (none) | S3 bucket for Tempo traces |
| `BACKUP_BUCKET` | (none) | S3 bucket for backups |

**Note:** Bucket names must be globally unique across all AWS accounts!

### Instance Type Recommendations

| Instance Type | vCPU | Memory | Use Case | Monthly Cost* |
|---------------|------|--------|----------|---------------|
| `t3.small` | 2 | 2GB | Testing only | ~$15 |
| `t3.medium` | 2 | 4GB | Small deployments | ~$30 |
| `t3.large` | 2 | 8GB | Medium deployments | ~$60 |
| `t3.xlarge` | 4 | 16GB | Production | ~$120 |
| `t3.2xlarge` | 8 | 32GB | Large production | ~$240 |

*Approximate costs for us-east-1 region

### Security: EXTERNAL_CIDRS

Control who can access your monitoring stack:

```bash
# Allow from anywhere (NOT recommended for production)
EXTERNAL_CIDRS="0.0.0.0/0"

# Allow only from your office IP
EXTERNAL_CIDRS="203.0.113.10/32"

# Allow from multiple locations
EXTERNAL_CIDRS="203.0.113.0/24,198.51.100.50/32"

# VPC/internal access only (most secure)
EXTERNAL_CIDRS=""
```

**Find your IP:** Visit https://whatismyip.com

### Template Parameters (Console Deployment)

Key parameters when deploying via AWS Console:

| Parameter | Description | Recommendation |
|-----------|-------------|----------------|
| **ProjectName** | Prefix for resource names | Use your organization name |
| **Environment** | Environment tag | `dev`, `staging`, or `prod` |
| **InstanceType** | EC2 instance size | Start with `t3.medium` |
| **RootVolumeSize** | OS disk size (GB) | Default 50GB usually sufficient |
| **DataVolumeSize** | Data disk size (GB) | Increase for more local storage |
| **EnableEIP** | Attach Elastic IP | Enable for consistent IP |
| **EnableSSM** | AWS Systems Manager access | Keep enabled |
| **EnableCloudWatchDatasource** | Grafana CloudWatch access | Keep enabled |

---

## After Deployment

### Getting Your Service URLs

**Method 1: Command Line**
```bash
# See all outputs
aws cloudformation describe-stacks \
  --stack-name monitoring-stack-simple \
  --region us-east-1 \
  --query 'Stacks[0].Outputs' \
  --output table

# Get just the instance IP
aws cloudformation describe-stacks \
  --stack-name monitoring-stack-simple \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
  --output text
```

**Method 2: AWS Console**
1. Go to **CloudFormation** → **Stacks**
2. Click your stack name
3. Click the **Outputs** tab
4. Copy the URLs you need

### Service Endpoints

Once deployed, services are available at:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Configuration Wizard** | `https://<instance-ip>:9443` | None |
| **Grafana** | `https://<instance-ip>` | admin / admin |
| **Prometheus** | `http://<instance-ip>:9090` | None |
| **Loki** | `http://<instance-ip>:3100` | None |
| **Alertmanager** | `http://<instance-ip>:9093` | None |
| **Mimir** | `http://<instance-ip>:9009` | None |
| **Tempo** | `http://<instance-ip>:3200` | None |

### First Steps

1. **Open Configuration Wizard**: `https://<instance-ip>:9443`
   - Follow the wizard to configure your monitoring stack
   - This is the easiest way to complete setup

2. **Access Grafana**: `https://<instance-ip>`
   - Login: `admin` / `admin`
   - You'll be prompted to change password

3. **Verify Services**: Check that all services are running

### SSH Access (Optional)

If you configured an SSH key:

```bash
# Get instance IP
INSTANCE_IP=$(aws cloudformation describe-stacks \
  --stack-name monitoring-stack-simple \
  --query 'Stacks[0].Outputs[?OutputKey==`InstancePublicIP`].OutputValue' \
  --output text)

# SSH to instance
ssh -i ~/.ssh/your-key.pem ubuntu@$INSTANCE_IP
```

---

## Updating Your Stack

Need to change configuration after deployment? Update instead of recreating.

### Update via Command Line

```bash
# Update to a larger instance type
aws cloudformation update-stack \
  --stack-name monitoring-stack-simple \
  --use-previous-template \
  --parameters \
    ParameterKey=InstanceType,ParameterValue=t3.large \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

### Update via AWS Console

1. Go to **CloudFormation** → **Stacks**
2. Select your stack
3. Click **Update**
4. Choose **Use current template**
5. Click **Next**
6. Change the parameters you want
7. Click through and **Update Stack**

**⚠️ Warning:** Some changes (like instance type) require replacing the EC2 instance, causing downtime!

---

## Troubleshooting

### Common Issues and Solutions

#### "Stack creation failed - no default VPC found"

**Cause:** Your AWS account doesn't have a default VPC.

**Solution:**
```bash
# Specify VPC and subnet manually
AWS_VPC=vpc-123456 AWS_SUBNET=subnet-abc123 ./deploy-stack-simple.sh
```

#### "CREATE_FAILED: Instance failed to launch"

**Possible causes:**

1. **Invalid AMI for region** - Each region has different AMI IDs
   - Solution: Let CloudFormation use latest Ubuntu (don't set AWS_AMI)

2. **Instance type unavailable** - Some types aren't in all regions
   - Solution: Try different instance: `INSTANCE_TYPE=t3.medium`

3. **Insufficient permissions** - IAM user lacks EC2 permissions
   - Solution: Add EC2FullAccess policy to your IAM user

#### "CREATE_FAILED: Bucket name already exists"

**Cause:** S3 bucket names must be globally unique.

**Solution:**
```bash
# Use unique bucket names
MIMIR_BUCKET=mycompany-metrics-$(date +%s) \
LOKI_BUCKET=mycompany-logs-$(date +%s) \
./deploy-stack-simple.sh
```

#### "Cannot access services after deployment"

**Solutions:**

1. **Services still starting** - Wait 5-10 minutes
2. **Wrong URL** - Use `https://` for Grafana (not `http://`)
3. **Security group issue** - Verify EXTERNAL_CIDRS includes your IP:
   ```bash
   EXTERNAL_CIDRS="$(curl -s https://checkip.amazonaws.com)/32" \
   ./deploy-stack-simple.sh
   ```

#### "Template validation failed"

**Cause:** Template file is corrupted.

**Solution:**
```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://monitoring-stack-simple.yaml \
  --region us-east-1
```

#### "Stack stuck in CREATE_IN_PROGRESS"

**Solution:**
1. Wait - can take 15-20 minutes
2. Check Events tab for errors
3. If truly stuck (30+ minutes):
   ```bash
   aws cloudformation delete-stack --stack-name monitoring-stack-simple
   # Wait, then try again
   ```

### Stack Status Reference

| Status | Meaning |
|--------|---------|
| `CREATE_IN_PROGRESS` | Creating resources |
| `CREATE_COMPLETE` | Successfully created ✅ |
| `CREATE_FAILED` | Creation failed ❌ |
| `UPDATE_IN_PROGRESS` | Updating resources |
| `UPDATE_COMPLETE` | Successfully updated ✅ |
| `DELETE_IN_PROGRESS` | Deleting resources |
| `DELETE_COMPLETE` | Successfully deleted ✅ |
| `ROLLBACK_IN_PROGRESS` | Rolling back due to error |

### Troubleshooting Checklist

Before asking for help:

- [ ] AWS credentials configured? (`aws sts get-caller-identity`)
- [ ] Correct region? (Check `AWS_REGION`)
- [ ] Necessary IAM permissions?
- [ ] Template file in current directory?
- [ ] Bucket names globally unique?
- [ ] Your IP in EXTERNAL_CIDRS?
- [ ] Waited 5-10 minutes for deployment?
- [ ] Using HTTPS for Grafana?
- [ ] Checked CloudFormation Events tab?

---

## Cost Estimates

### Simple Stack Monthly Costs (us-east-1)

**EC2 Instances:**

| Instance Type | Hourly | Monthly (~730 hours) |
|---------------|--------|----------------------|
| t3.small | $0.0208 | ~$15 |
| t3.medium | $0.0416 | ~$30 |
| t3.large | $0.0832 | ~$60 |
| t3.xlarge | $0.1664 | ~$120 |
| t3.2xlarge | $0.3328 | ~$240 |

**Additional Costs:**
- **EBS Storage**: ~$0.10/GB/month (root + data volumes)
- **S3 Storage**: ~$0.023/GB/month (if using buckets)
- **Data Transfer**: $0.09/GB after 100GB free/month
- **Elastic IP**: $0.005/hour if not attached

### Example Total Costs

**Testing (t3.small, 80GB storage):**
- Instance: $15/month
- Storage: $8/month
- **Total: ~$25/month**

**Small Production (t3.medium, 150GB, S3):**
- Instance: $30/month
- Storage: $15/month
- S3 (100GB): $2.30/month
- **Total: ~$50/month**

**Medium Production (t3.large, 250GB, S3):**
- Instance: $60/month
- Storage: $25/month
- S3 (500GB): $11.50/month
- **Total: ~$100/month**

### Cost Optimization Tips

1. Use Savings Plans or Reserved Instances (30-70% discount)
2. Delete unused S3 data regularly
3. Use S3 lifecycle policies for old data
4. Stop instances when not needed (dev/test)
5. Use AWS Cost Explorer to track spending

---

## Cleanup

### Delete Stack and Resources

**Method 1: Command Line**

```bash
# Delete the stack
aws cloudformation delete-stack \
  --stack-name monitoring-stack-simple \
  --region us-east-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name monitoring-stack-simple \
  --region us-east-1

# Verify deletion
aws cloudformation describe-stacks \
  --stack-name monitoring-stack-simple \
  --region us-east-1
```

**Method 2: AWS Console**

1. Go to **CloudFormation** → **Stacks**
2. Select your stack
3. Click **Delete**
4. Confirm deletion
5. Wait for status **DELETE_COMPLETE**

### Important: What Gets Deleted

**Automatically Deleted:**
- EC2 instances
- Security groups
- IAM roles and policies
- Elastic IPs (if created)

**NOT Automatically Deleted:**
- **S3 buckets with data** - Safety feature
- **CloudWatch Logs** - Retained by default

### Delete S3 Buckets

CloudFormation won't delete buckets containing data. To remove them:

**Command Line:**
```bash
# List buckets
aws s3 ls | grep "monitoring"

# Empty and delete each bucket
aws s3 rm s3://your-bucket-name --recursive
aws s3 rb s3://your-bucket-name
```

**AWS Console:**
1. Go to **S3**
2. Select the bucket
3. Click **Empty** to remove objects
4. Click **Delete** to remove bucket

---

## Advanced Topics

### Import Existing Resources

If you have existing AWS resources and want CloudFormation to manage them:

1. Edit `import-resources.json` with your resource IDs
2. Edit `import-stack.sh` with parameters
3. Run: `./import-stack.sh`

**Note:** This is advanced - only use if you understand CloudFormation imports.

### Template Validation

```bash
# Validate simple stack
aws cloudformation validate-template \
  --template-body file://monitoring-stack-simple.yaml \
  --region us-east-1

# Validate full stack
aws cloudformation validate-template \
  --template-body file://monitoring-stack.yaml \
  --region us-east-1
```

**Note:** Large templates may exceed validation size limits.

### Custom User Data

Modify instance initialization by providing custom user data:

```bash
# Create custom script
cat > custom-init.sh <<'EOF'
#!/bin/bash
# Your custom initialization here
EOF

# Deploy with custom script
aws cloudformation create-stack \
  --stack-name my-stack \
  --template-body file://monitoring-stack-simple.yaml \
  --parameters ParameterKey=UserDataScript,ParameterValue="$(cat custom-init.sh)" \
  --capabilities CAPABILITY_IAM
```

---

## Quick Reference

### Essential Commands

```bash
# Deploy simple stack
./deploy-stack-simple.sh

# Deploy with options
INSTANCE_TYPE=t3.large AWS_KEY_NAME=my-key ./deploy-stack-simple.sh

# Check status
aws cloudformation describe-stacks --stack-name monitoring-stack-simple

# Get outputs
aws cloudformation describe-stacks --stack-name monitoring-stack-simple \
  --query 'Stacks[0].Outputs' --output table

# Update stack
aws cloudformation update-stack --stack-name monitoring-stack-simple \
  --use-previous-template --parameters <params>

# Delete stack
aws cloudformation delete-stack --stack-name monitoring-stack-simple

# List all stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE
```

### Environment Variables

```bash
# Basic
STACK_NAME=my-monitoring
AWS_REGION=us-east-1
INSTANCE_TYPE=t3.medium

# Network
AWS_VPC=vpc-123456
AWS_SUBNET=subnet-abc123
EXTERNAL_CIDRS="1.2.3.4/32"

# Access
AWS_KEY_NAME=my-keypair

# Storage
MIMIR_BUCKET=metrics-bucket
LOKI_BUCKET=logs-bucket
TEMPO_BUCKET=traces-bucket
BACKUP_BUCKET=backups-bucket
```

---

## Next Steps

### After Successful Deployment

1. **Configure Monitoring Stack**
   - Use wizard at `https://<ip>:9443`
   - Or deploy with Ansible

2. **Set Up Grafana**
   - Add data sources
   - Import dashboards
   - Configure users

3. **Configure Alerts**
   - Set up Alertmanager
   - Add notification channels
   - Create alert rules

4. **Security Hardening**
   - Change Grafana password
   - Restrict EXTERNAL_CIDRS
   - Review IAM permissions
   - Enable MFA on AWS account

### Learn More

- **CloudFormation Docs**: https://docs.aws.amazon.com/cloudformation/
- **AWS CLI Reference**: https://docs.aws.amazon.com/cli/
- **Monitoring Stack**: See main README.md
- **Grafana Docs**: https://grafana.com/docs/

---

## Support

**CloudFormation Issues:**
- Check AWS CloudFormation documentation
- Review stack Events tab
- Use AWS Support (if available)

**Monitoring Software Issues:**
- See main project README.md
- Check service logs on EC2
- Review Ansible documentation

**AWS Account/Billing:**
- Contact AWS Support
- Use AWS Cost Explorer

---

**Happy Monitoring! 🎉**

Remember: CloudFormation creates the infrastructure. Complete setup by using the configuration wizard at `https://<instance-ip>:9443` after deployment!
