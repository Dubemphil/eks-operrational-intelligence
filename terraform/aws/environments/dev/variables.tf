variable "aws_region" {
  type        = string
  description = "AWS deployment region"
  default     = "eu-north-1"
}

variable "environment" {
  type        = string
  description = "Target deployment environment"
  default     = "dev"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
  default     = "omnipulse-eks"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes Version"
  default     = "1.31"
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for EKS worker nodes"
  default     = ["t3.large"]
}

variable "capacity_type" {
  type        = string
  description = "Capacity type: ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "desired_node_count" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 2
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 2
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 3
}

variable "enable_github_oidc" {
  type        = bool
  description = "Whether to provision the GitHub Actions OIDC role (false: bootstrapped via bootstrap module)"
  default     = false
}

variable "github_repo" {
  type        = string
  description = "GitHub repository (e.g. your-org/operational-intelligence)"
  default     = "Dubemphil/eks-operrational-intelligence"
}

variable "create_oidc_provider" {
  type        = bool
  description = "Whether to create the GitHub OIDC provider"
  default     = false
}

variable "enable_argocd" {
  type        = bool
  description = "Whether to install ArgoCD via Helm"
  default     = false
}

variable "enable_slack_notifications" {
  type        = bool
  description = "Enable Slack alerts for ArgoCD and Robusta"
  default     = false
}

variable "slack_token" {
  type        = string
  description = "Slack Bot Token"
  default     = ""
  sensitive   = true
}

variable "slack_channel" {
  type        = string
  description = "Slack channel for triage alerts"
  default     = "operational-intelligence"
}

variable "github_pat_token" {
  type        = string
  description = "GitHub PAT Token for ArgoCD private repos"
  default     = ""
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Root domain name for Route 53 Hosted Zone and ACM certificate"
  default     = "devopsstandard.name.ng"
}


