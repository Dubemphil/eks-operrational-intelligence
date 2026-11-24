variable "domain_name" {
  type        = string
  description = "Root domain name for Route 53 Hosted Zone and ACM wildcard certificate"
}

variable "environment" {
  type        = string
  description = "Target deployment environment (dev/prod)"
}

variable "oidc_provider_arn" {
  type        = string
  description = "EKS OIDC Provider ARN for IRSA"
}

variable "oidc_provider_url" {
  type        = string
  description = "EKS OIDC Provider URL (without https://)"
}
