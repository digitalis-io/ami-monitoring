#!/bin/bash

# Import existing AWS resources into CloudFormation stack

STACK_NAME="monitoring-stack"
REGION="us-east-1"
VPC_ID="vpc-EXISTING-VPC-ID"
SUBNET_IDS="subnet-EXISTING-1,subnet-EXISTING-2"

echo "Creating change set for import..."
aws cloudformation create-change-set \
  --stack-name $STACK_NAME \
  --change-set-name import-existing-resources \
  --change-set-type IMPORT \
  --resources-to-import file://import-resources.json \
  --template-body file://monitoring-stack.yaml \
  --parameters \
    ParameterKey=VpcId,ParameterValue=$VPC_ID \
    ParameterKey=SubnetIds,ParameterValue=\"$SUBNET_IDS\" \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Execute the change set with:"
echo "aws cloudformation execute-change-set --change-set-name import-existing-resources --stack-name $STACK_NAME --region $REGION"