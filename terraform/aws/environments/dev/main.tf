# AWS Production/Dev Environment Root Configuration
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0, < 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.26.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "OmniPulse"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

# Kubernetes and Helm Providers authenticated against EKS
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# 1. Multi-AZ VPC Network
module "vpc" {
  source       = "../../modules/vpc"
  environment  = var.environment
  cluster_name = "${var.cluster_name}-${var.environment}"
  vpc_cidr     = var.vpc_cidr
}

# 2. Managed EKS Cluster (v1.31)
module "eks" {
  source             = "../../modules/eks"
  environment        = var.environment
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_types     = var.instance_types
  capacity_type      = var.capacity_type
  desired_node_count = var.desired_node_count
  min_node_count     = var.min_node_count
  max_node_count     = var.max_node_count
}

# 3. Storage: S3 Telemetry Archive & DynamoDB Immutable Audit Log Table
module "storage" {
  source      = "../../modules/storage"
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
}

# 4. IRSA (IAM Roles for Service Accounts)
module "irsa" {
  source                       = "../../modules/irsa"
  environment                  = var.environment
  oidc_provider_arn            = module.eks.oidc_provider_arn
  oidc_provider_url            = module.eks.oidc_provider_url
  dynamodb_audit_table_arn     = module.storage.dynamodb_audit_table_arn
  dlq_quarantine_bucket_arn    = module.storage.dlq_quarantine_bucket_arn
  telemetry_archive_bucket_arn = module.storage.telemetry_archive_bucket_arn
}

# 5. ECR Container Image Repositories
module "ecr" {
  source      = "../../modules/ecr"
  environment = var.environment
}

# 6. Keyless GitHub Actions OIDC Authentication
module "oidc_github" {
  count                = var.enable_github_oidc ? 1 : 0
  source               = "../../modules/oidc_github"
  environment          = var.environment
  account_id           = data.aws_caller_identity.current.account_id
  aws_region           = var.aws_region
  github_repo          = var.github_repo
  create_oidc_provider = var.create_oidc_provider
}

# 7. Argo CD GitOps Engine Deployment
module "argocd" {
  count                      = var.enable_argocd ? 1 : 0
  source                     = "../../modules/argocd"
  environment                = var.environment
  server_service_type        = "ClusterIP"
  ha_mode                    = false
  enable_slack_notifications = var.enable_slack_notifications
  slack_token                = var.slack_token
  slack_channel              = var.slack_channel
  github_repo_url            = "https://github.com/${var.github_repo}.git"
  github_pat_token           = var.github_pat_token

  depends_on = [module.eks]
}

