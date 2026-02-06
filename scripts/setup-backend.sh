#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (keep these names for compatibility with any other scripts)
BUCKET_NAME="${BUCKET_NAME:-project-bedrock-terraform-state-alt-soe-025-1162}"
TABLE_NAME="${TABLE_NAME:-project-bedrock-state-lock}"
REGION="${REGION:-us-east-1}"

PROJECT_TAG_KEY="${PROJECT_TAG_KEY:-Project}"
PROJECT_TAG_VALUE="${PROJECT_TAG_VALUE:-Bedrock}"

# -------- Helpers --------
die() {
  echo -e "${RED}❌ $*${NC}" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Terraform Backend Setup${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

# Pre-flight checks
need_cmd aws

# Confirm AWS identity early (prevents “wrong account” disasters)
echo -e "${GREEN}Checking AWS identity...${NC}"
aws sts get-caller-identity --output table >/dev/null \
  || die "AWS credentials are not working. Fix AWS CLI auth before continuing."
echo -e "${GREEN}✅ AWS credentials look good${NC}"
echo ""

# -------- S3 Bucket --------
echo -e "${GREEN}Checking S3 bucket existence...${NC}"

# head-bucket:
# - Exit 0: bucket exists and is accessible
# - Exit non-zero: could be "not found" OR "exists but forbidden" OR other
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
  echo -e "${YELLOW}⚠️  S3 bucket '$BUCKET_NAME' already exists and is accessible. Skipping creation.${NC}"
else
  # Attempt to create; if it already exists in someone else's account, AWS will error clearly.
  echo -e "${GREEN}Creating S3 bucket for Terraform state...${NC}"

  # us-east-1 special case: do NOT set LocationConstraint for create-bucket
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" >/dev/null
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration "LocationConstraint=$REGION" >/dev/null
  fi

  echo -e "${GREEN}✅ S3 bucket created${NC}"
fi

echo -e "${GREEN}Enabling versioning...${NC}"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --versioning-configuration Status=Enabled >/dev/null
echo -e "${GREEN}✅ Versioning enabled${NC}"

echo -e "${GREEN}Blocking public access...${NC}"
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
echo -e "${GREEN}✅ Public access blocked${NC}"

echo -e "${GREEN}Adding encryption...${NC}"
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' >/dev/null
echo -e "${GREEN}✅ Encryption enabled${NC}"

# Tagging (helps meet "Project=Bedrock" discipline; safe even if already tagged)
echo -e "${GREEN}Tagging S3 bucket...${NC}"
aws s3api put-bucket-tagging \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --tagging "TagSet=[{Key=$PROJECT_TAG_KEY,Value=$PROJECT_TAG_VALUE}]" >/dev/null
echo -e "${GREEN}✅ Bucket tagged${NC}"

# -------- DynamoDB Lock Table --------
echo -e "${GREEN}Checking DynamoDB table existence...${NC}"
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  DynamoDB table '$TABLE_NAME' already exists. Skipping creation.${NC}"
else
  echo -e "${GREEN}Creating DynamoDB table for state locking...${NC}"
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" \
    --tags Key="$PROJECT_TAG_KEY",Value="$PROJECT_TAG_VALUE" >/dev/null

  echo -e "${GREEN}✅ DynamoDB table created${NC}"

  echo -e "${YELLOW}Waiting for table to become active...${NC}"
  aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
  echo -e "${GREEN}✅ DynamoDB table is active${NC}"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Backend setup complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "S3 Bucket: ${YELLOW}$BUCKET_NAME${NC}"
echo -e "DynamoDB Table: ${YELLOW}$TABLE_NAME${NC}"
echo -e "Region: ${YELLOW}$REGION${NC}"
echo ""
echo -e "${YELLOW}Next step: Initialize Terraform with 'terraform init' in the terraform/ directory${NC}"
