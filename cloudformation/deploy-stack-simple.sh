#!/bin/bash

# Deploy Simple CloudFormation Stack (Single EC2 instance with minimal configuration)

STACK_NAME="${STACK_NAME:-monitoring-stack-simple}"
REGION="${AWS_REGION:-us-east-1}"

# Optional parameters (will use defaults if not provided)
VPC_ID="${AWS_VPC}"
SUBNET_ID="${AWS_SUBNET}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.medium}"
KEY_NAME="${AWS_KEY_NAME}"
EXTERNAL_CIDRS="${EXTERNAL_CIDRS:-0.0.0.0/0}"
AMI_ID="${AWS_AMI:-ami-0520d2aad6b9f5e14}"

# Storage bucket parameters (optional)
MIMIR_BUCKET="${MIMIR_BUCKET}"
LOKI_BUCKET="${LOKI_BUCKET}"
TEMPO_BUCKET="${TEMPO_BUCKET}"
BACKUP_BUCKET="${BACKUP_BUCKET}"

# Show usage if --help is passed
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0"
    echo ""
    echo "This script deploys a simplified monitoring stack with a single EC2 instance."
    echo "It will use the default VPC and subnet if not specified."
    echo ""
    echo "Optional Environment Variables:"
    echo "  STACK_NAME         - CloudFormation stack name (default: monitoring-stack-simple)"
    echo "  AWS_REGION         - AWS region (default: us-east-1)"
    echo "  AWS_VPC            - VPC ID (default: uses default VPC)"
    echo "  AWS_SUBNET         - Subnet ID (default: uses default subnet)"
    echo "  INSTANCE_TYPE      - EC2 instance type (default: t3.medium)"
    echo "  AWS_KEY_NAME       - SSH key pair name for EC2 access (optional)"
    echo "  AWS_AMI            - AMI ID (default: ami-0a14956fce1f3adcb)"
    echo "  EXTERNAL_CIDRS     - External CIDR blocks for access (default: 0.0.0.0/0)"
    echo "  MIMIR_BUCKET       - S3 bucket for Mimir storage (optional)"
    echo "  LOKI_BUCKET        - S3 bucket for Loki storage (optional)"
    echo "  TEMPO_BUCKET       - S3 bucket for Tempo storage (optional)"
    echo "  BACKUP_BUCKET      - S3 bucket for backups (optional)"
    echo ""
    echo "Examples:"
    echo "  # Deploy with all defaults (uses default VPC)"
    echo "  ./deploy-stack-simple.sh"
    echo ""
    echo "  # Deploy with custom instance type and SSH key"
    echo "  INSTANCE_TYPE=t3.large AWS_KEY_NAME=my-key ./deploy-stack-simple.sh"
    echo ""
    echo "  # Deploy with custom AMI"
    echo "  AWS_AMI=ami-0123456789abcdef ./deploy-stack-simple.sh"
    echo ""
    echo "  # Deploy with specific VPC and storage buckets"
    echo "  AWS_VPC=vpc-123456 LOKI_BUCKET=my-loki-bucket ./deploy-stack-simple.sh"
    echo ""
    echo "  # Deploy with custom stack name"
    echo "  STACK_NAME=my-monitoring ./deploy-stack-simple.sh"
    exit 0
fi

echo "================================================"
echo "Deploying Simple Monitoring Stack"
echo "================================================"
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Instance Type: $INSTANCE_TYPE"
echo "AMI ID: $AMI_ID"
if [ -n "$VPC_ID" ]; then
    echo "VPC: $VPC_ID"
else
    echo "VPC: Using default VPC"
fi
if [ -n "$SUBNET_ID" ]; then
    echo "Subnet: $SUBNET_ID"
else
    echo "Subnet: Using default subnet"
fi
echo "================================================"
# Create a bucket name for template upload (or use existing)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $REGION)
if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: Unable to get AWS account ID. Please ensure AWS credentials are configured."
    exit 1
fi

BUCKET_NAME="cf-templates-${ACCOUNT_ID}-${REGION}"

echo "Checking if S3 bucket exists..."
if ! aws s3 ls "s3://${BUCKET_NAME}" --region $REGION 2>/dev/null; then
    echo "Creating S3 bucket for CloudFormation templates..."
    if [ "$REGION" = "us-east-1" ]; then
        aws s3 mb "s3://${BUCKET_NAME}" --region $REGION
    else
        aws s3 mb "s3://${BUCKET_NAME}" --region $REGION --create-bucket-configuration LocationConstraint=$REGION
    fi
fi

echo "Uploading template to S3..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEMPLATE_KEY="monitoring-stack-simple-${TIMESTAMP}.yaml"
aws s3 cp monitoring-stack-simple.yaml "s3://${BUCKET_NAME}/${TEMPLATE_KEY}" --region $REGION

if [ $? -ne 0 ]; then
    echo "Error: Failed to upload template to S3"
    exit 1
fi
TEMPLATE_URL="https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/${TEMPLATE_KEY}"

# Build parameters array
PARAMS=""

# Add VPC and Subnet if provided
if [ -n "$VPC_ID" ]; then
    PARAMS="$PARAMS ParameterKey=VpcId,ParameterValue=$VPC_ID"
fi

if [ -n "$SUBNET_ID" ]; then
    PARAMS="$PARAMS ParameterKey=SubnetId,ParameterValue=$SUBNET_ID"
fi

# Add instance configuration
PARAMS="$PARAMS ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE"

# Add key pair if provided
echo "Key provided: $KEY_NAME"
if [ -n "$KEY_NAME" ]; then
    PARAMS="$PARAMS ParameterKey=KeyPairName,ParameterValue=$KEY_NAME"
fi

# Add AMI (always provided since we have a default)
PARAMS="$PARAMS ParameterKey=AmiId,ParameterValue=$AMI_ID"

# Add external CIDR access
PARAMS="$PARAMS ParameterKey=AllowedExternalCidrs,ParameterValue=\"$EXTERNAL_CIDRS\""

# Add S3 buckets if provided
if [ -n "$MIMIR_BUCKET" ]; then
    PARAMS="$PARAMS ParameterKey=MimirBucketName,ParameterValue=$MIMIR_BUCKET"
fi

if [ -n "$LOKI_BUCKET" ]; then
    PARAMS="$PARAMS ParameterKey=LokiBucketName,ParameterValue=$LOKI_BUCKET"
fi

if [ -n "$TEMPO_BUCKET" ]; then
    PARAMS="$PARAMS ParameterKey=TempoBucketName,ParameterValue=$TEMPO_BUCKET"
fi

if [ -n "$BACKUP_BUCKET" ]; then
    PARAMS="$PARAMS ParameterKey=BackupBucketName,ParameterValue=$BACKUP_BUCKET"
fi

echo "Creating CloudFormation stack..."
if [ -n "$PARAMS" ]; then
    aws cloudformation create-stack \
      --stack-name $STACK_NAME \
      --template-url $TEMPLATE_URL \
      --parameters $PARAMS \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
      --region $REGION
else
    # No parameters, use all defaults
    aws cloudformation create-stack \
      --stack-name $STACK_NAME \
      --template-url $TEMPLATE_URL \
      --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
      --region $REGION
fi

if [ $? -eq 0 ]; then
    echo "================================================"
    echo "Stack creation initiated successfully!"
    echo ""
    echo "Monitor stack progress:"
    echo "  aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].StackStatus' --output text"
    echo ""
    echo "Wait for stack completion:"
    echo "  aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION"
    echo ""
    echo "Get stack outputs:"
    echo "  aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs' --output table"
    echo ""
    echo "Once deployed, the monitoring endpoints will be available at the IPs shown in the outputs."
else
    echo "Error: Stack creation failed. Please check the error messages above."
    exit 1
fi
