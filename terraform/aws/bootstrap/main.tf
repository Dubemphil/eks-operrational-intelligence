# 1-Time Bootstrap Configuration for AWS Remote State & GitHub Actions OIDC
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }

  # Local state because this module creates the remote S3 backend
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# 1. S3 Bucket for Terraform Remote State
resource "aws_s3_bucket" "tf_state" {
  bucket        = "${var.bucket_prefix}-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. DynamoDB Table for Distributed State Locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

# 3. GitHub Actions OIDC Identity Provider
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# 4. IAM Deployer Role for GitHub Actions
resource "aws_iam_role" "github_deployer" {
  name = "omnipulse-github-deployer-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Dubemphil@136280265/eks-operrational-intelligence*:environment:production",
              "repo:Dubemphil@136280265/eks-operrational-intelligence*:environment:dev",
              "repo:Dubemphil@136280265/eks-operrational-intelligence*:*",
              "repo:${var.github_repo}:*",
              "*"
            ]
          }
        }
      }
    ]
  })
}

# PowerUser permissions to deploy VPC, EKS, S3, DynamoDB, ECR
resource "aws_iam_role_policy_attachment" "github_deployer_poweruser" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM permissions to manage application roles, IRSA, and instance profiles
resource "aws_iam_role_policy" "github_deployer_iam" {
  name = "omnipulse-github-deployer-iam-policy"
  role = aws_iam_role.github_deployer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:*"
        ]
        Resource = "*"
      }
    ]
  })
}

