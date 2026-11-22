#!/usr/bin/env bash
# ==============================================================================
# OmniPulse AWS Bootstrap Script (One-Time Execution)
# Creates:
#   1. S3 State Bucket (with Versioning + Encryption + Block Public Access)
#   2. DynamoDB Lock Table (omnipulse-tfstate-lock)
#   3. GitHub Actions OIDC Provider
#   4. GitHub Actions Deployer IAM Role
# ==============================================================================

set -euo pipefail

AWS_REGION="${AWS_REGION:-eu-north-1}"
GITHUB_REPO="${GITHUB_REPO:-Dubemphil/eks-operrational-intelligence}"
LOCK_TABLE="omnipulse-tfstate-lock"

echo "==> Detecting AWS Account Identity..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "    AWS Account ID: ${AWS_ACCOUNT_ID}"
echo "    Target Region:  ${AWS_REGION}"
echo "    GitHub Repo:    ${GITHUB_REPO}"

STATE_BUCKET="devopsstandard-tfstate-${AWS_ACCOUNT_ID}"

# 1. Create S3 Bucket
echo "==> Creating S3 State Bucket: ${STATE_BUCKET}..."
if [ "${AWS_REGION}" == "us-east-1" ]; then
  aws s3api create-bucket --bucket "${STATE_BUCKET}" --region "${AWS_REGION}" || true
else
  aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region "${AWS_REGION}" \
    --create-bucket-configuration LocationConstraint="${AWS_REGION}" || true
fi

echo "==> Enabling Bucket Versioning..."
aws s3api put-bucket-versioning \
  --bucket "${STATE_BUCKET}" \
  --versioning-configuration Status=Enabled

echo "==> Enabling Server-Side Encryption..."
aws s3api put-bucket-encryption \
  --bucket "${STATE_BUCKET}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "==> Blocking Public Access..."
aws s3api put-public-access-block \
  --bucket "${STATE_BUCKET}" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# 2. Create DynamoDB Lock Table
echo "==> Creating DynamoDB Lock Table: ${LOCK_TABLE}..."
aws dynamodb create-table \
  --table-name "${LOCK_TABLE}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${AWS_REGION}" || true

# 3. Create GitHub OIDC Provider
echo "==> Creating GitHub OIDC Provider in IAM..."
aws iam create-open-id-connect-provider \
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list "sts.amazonaws.com" \
  --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" "1c58760252c5c275e352d92ee143f12d8e364646" || true

OIDC_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

# 4. Create IAM Deployer Role
ROLE_NAME="omnipulse-github-deployer-dev"
echo "==> Creating IAM Role: ${ROLE_NAME}..."

TMP_TRUST_POLICY=$(mktemp)
cat <<EOF > "${TMP_TRUST_POLICY}"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --assume-role-policy-document "file://${TMP_TRUST_POLICY}" || \
aws iam update-assume-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-document "file://${TMP_TRUST_POLICY}"
rm -f "${TMP_TRUST_POLICY}"

echo "==> Attaching AdministratorAccess Policy..."
aws iam attach-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

echo ""
echo "=============================================================================="
echo "🎉 BOOTSTRAP COMPLETE! Add these 4 Secrets in GitHub Repository Settings:"
echo "   (Settings -> Secrets and variables -> Actions -> New repository secret)"
echo "=============================================================================="
echo "AWS_ROLE_ARN    : ${ROLE_ARN}"
echo "TF_STATE_BUCKET : ${STATE_BUCKET}"
echo "TF_LOCK_TABLE   : ${LOCK_TABLE}"
echo "AWS_REGION      : ${AWS_REGION}"
echo "=============================================================================="

