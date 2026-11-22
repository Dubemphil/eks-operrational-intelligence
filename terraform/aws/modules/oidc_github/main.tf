# GitHub Actions OIDC Keyless Authentication Module
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

data "tls_certificate" "github" {
  count = var.create_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

# 1. GitHub OIDC Provider (only if not already created in AWS account)
resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]

  tags = {
    Name        = "GitHub Actions OIDC Provider"
    Environment = var.environment
  }
}

locals {
  provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

# 2. IAM Role for GitHub Actions Deployer
resource "aws_iam_role" "github_deployer" {
  name = "omnipulse-github-deployer-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHub Actions CI/CD Role"
    Environment = var.environment
  }
}

# 3. Least-privilege permissions for GitHub Actions (ECR push, EKS describe)
resource "aws_iam_policy" "github_deployer" {
  name        = "omnipulse-github-deployer-policy-${var.environment}"
  description = "Allows GitHub Actions to push container images to ECR and update EKS workloads"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = [
          "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/omnipulse/*",
          "arn:aws:ecr:${var.aws_region}:${var.account_id}:repository/microservice-app"
        ]
      },
      {
        Sid    = "EKSDescribe"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:${var.account_id}:cluster/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_deployer" {
  role       = aws_iam_role.github_deployer.name
  policy_arn = aws_iam_policy.github_deployer.arn
}

