#!/bin/bash

# Deploy CloudFormation stack (CREATE new resources, not import existing ones)

STACK_NAME="monitoring-stack"
REGION="${AWS_REGION:-us-east-1}"
VPC_ID="${AWS_VPC}"
SUBNET_IDS="${AWS_SUBNETS}"
AMI_ID="${AWS_AMI:-ami-0520d2aad6b9f5e14}"

# Check if required parameters are set
if [ -z "$VPC_ID" ] || [ -z "$SUBNET_IDS" ]; then
    echo "Error: VPC_ID and SUBNET_IDS must be set"
    echo "Usage: AWS_VPC=vpc-xxx AWS_SUBNETS='subnet-xxx,subnet-yyy' ./deploy-stack.sh"
    exit 1
fi

# Create a bucket name for template upload (or use existing)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $REGION)
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
TEMPLATE_KEY="monitoring-stack-${TIMESTAMP}.yaml"
aws s3 cp monitoring-stack.yaml "s3://${BUCKET_NAME}/${TEMPLATE_KEY}" --region $REGION

TEMPLATE_URL="https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com/${TEMPLATE_KEY}"

echo "Creating CloudFormation stack..."
aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-url $TEMPLATE_URL \
  --parameters \
    ParameterKey=VpcId,ParameterValue=$VPC_ID \
    ParameterKey=SubnetIds,ParameterValue=\"$SUBNET_IDS\" \
    ParameterKey=AllowedExternalCidrs,ParameterValue=0.0.0.0/0 \
    ParameterKey=LbSubnetIds,ParameterValue=\"$SUBNET_IDS\" \
    ParameterKey=AmiId,ParameterValue=$AMI_ID \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Stack creation initiated. Check status with:"
echo "aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION"
