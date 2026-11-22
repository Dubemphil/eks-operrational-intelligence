variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository formatted as owner/repo (e.g. your-org/operational-intelligence)"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
  default     = "us-east-1"
}

variable "create_oidc_provider" {
  type        = bool
  description = "Whether to create the GitHub OIDC provider if it does not already exist"
  default     = true
}

variable "existing_oidc_provider_arn" {
  type        = string
  description = "ARN of existing GitHub OIDC provider if create_oidc_provider is false"
  default     = ""
}

