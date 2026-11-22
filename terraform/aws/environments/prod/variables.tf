variable "aws_region" {
  type        = string
  description = "AWS deployment region"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Target deployment environment"
  default     = "prod"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
  default     = "omnipulse-eks-prod"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.1.0.0/16"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes Version"
  default     = "1.31"
}

variable "instance_types" {
  type        = list(string)
  description = "Instance types for production EKS worker nodes"
  default     = ["m5.xlarge", "m5a.xlarge"]
}

variable "capacity_type" {
  type        = string
  description = "Capacity type: ON_DEMAND or SPOT"
  default     = "ON_DEMAND"
}

variable "desired_node_count" {
  type        = number
  description = "Desired number of worker nodes"
  default     = 5
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of worker nodes"
  default     = 3
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of worker nodes"
  default     = 10
}

variable "enable_github_oidc" {
  type        = bool
  description = "Whether to provision the GitHub Actions OIDC role"
  default     = true
}

variable "github_repo" {
  type        = string
  description = "GitHub repository (e.g. your-org/operational-intelligence)"
  default     = "Dubemphil/eks-operrational-intelligence"
}

variable "create_oidc_provider" {
  type        = bool
  description = "Whether to create the GitHub OIDC provider (false if dev/account already created it)"
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
  default     = "operational-intelligence-prod"
}

variable "github_pat_token" {
  type        = string
  description = "GitHub PAT Token for ArgoCD private repos"
  default     = ""
  sensitive   = true
}

