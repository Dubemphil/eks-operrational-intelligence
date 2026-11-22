# ==============================================================================
# OmniPulse AWS Bootstrap Script (PowerShell)
# ==============================================================================

$ErrorActionPreference = "Stop"

$AwsRegion = if ($env:AWS_REGION) { $env:AWS_REGION } else { "eu-north-1" }
$GithubRepo = "Dubemphil/eks-operrational-intelligence"
$LockTable = "omnipulse-tfstate-lock"

Write-Host "==> Detecting AWS Account Identity..." -ForegroundColor Cyan
$AccountId = (aws sts get-caller-identity --query Account --output text).Trim()
Write-Host "    AWS Account ID: $AccountId"
Write-Host "    Target Region:  $AwsRegion"
Write-Host "    GitHub Repo:    $GithubRepo"

$StateBucket = "devopsstandard-tfstate-$AccountId"

# 1. Create S3 Bucket
Write-Host "==> Creating S3 State Bucket: $StateBucket..." -ForegroundColor Cyan
try {
    aws s3api create-bucket `
        --bucket $StateBucket `
        --region $AwsRegion `
        --create-bucket-configuration LocationConstraint=$AwsRegion
} catch {
    Write-Host "Bucket may already exist, continuing..."
}

aws s3api put-bucket-versioning `
    --bucket $StateBucket `
    --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption `
    --bucket $StateBucket `
    --server-side-encryption-configuration '{\"Rules\": [{\"ApplyServerSideEncryptionByDefault\": {\"SSEAlgorithm\": \"AES256\"}}]}'

aws s3api put-public-access-block `
    --bucket $StateBucket `
    --public-access-block-configuration '{\"BlockPublicAcls\": true, \"IgnorePublicAcls\": true, \"BlockPublicPolicy\": true, \"RestrictPublicBuckets\": true}'

# 2. Create DynamoDB Lock Table
Write-Host "==> Creating DynamoDB Lock Table: $LockTable..." -ForegroundColor Cyan
try {
    aws dynamodb create-table `
        --table-name $LockTable `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $AwsRegion
} catch {
    Write-Host "Table may already exist, continuing..."
}

# 3. Create GitHub OIDC Provider
Write-Host "==> Creating GitHub OIDC Provider in IAM..." -ForegroundColor Cyan
try {
    aws iam create-open-id-connect-provider `
        --url "https://token.actions.githubusercontent.com" `
        --client-id-list "sts.amazonaws.com" `
        --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1" "1c58760252c5c275e352d92ee143f12d8e364646"
} catch {
    Write-Host "OIDC provider may already exist, continuing..."
}

$OidcArn = "arn:aws:iam::$AccountId`:oidc-provider/token.actions.githubusercontent.com"

# 4. Create IAM Deployer Role
$RoleName = "omnipulse-github-deployer-dev"
Write-Host "==> Creating IAM Role: $RoleName..." -ForegroundColor Cyan

$TrustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "$OidcArn"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:$GithubRepo`:*"
        }
      }
    }
  ]
}
"@

$TrustPolicyFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $TrustPolicyFile -Value $TrustPolicy

try {
    aws iam create-role --role-name $RoleName --assume-role-policy-document "file://$TrustPolicyFile"
} catch {
    aws iam update-assume-role-policy --role-name $RoleName --policy-document "file://$TrustPolicyFile"
}
Remove-Item -Path $TrustPolicyFile -Force

aws iam attach-role-policy --role-name $RoleName --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

$RoleArn = "arn:aws:iam::$AccountId`:role/$RoleName"

Write-Host ""
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "🎉 BOOTSTRAP COMPLETE! Add these 4 Secrets in GitHub Repository Settings:" -ForegroundColor Green
Write-Host "   (Settings -> Secrets and variables -> Actions -> New repository secret)" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "AWS_ROLE_ARN    : $RoleArn" -ForegroundColor Yellow
Write-Host "TF_STATE_BUCKET : $StateBucket" -ForegroundColor Yellow
Write-Host "TF_LOCK_TABLE   : $LockTable" -ForegroundColor Yellow
Write-Host "AWS_REGION      : $AwsRegion" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Green

