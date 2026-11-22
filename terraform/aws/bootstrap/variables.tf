variable "aws_region" {
  type        = string
  description = "AWS deployment region"
  default     = "eu-north-1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository formatted as owner/repo"
  default     = "Dubemphil/eks-operrational-intelligence"
}

variable "bucket_prefix" {
  type        = string
  description = "Prefix for the S3 remote state bucket"
  default     = "devopsstandard-tfstate"
}

variable "lock_table_name" {
  type        = string
  description = "DynamoDB state locking table name"
  default     = "omnipulse-tfstate-lock"
}

variable "create_oidc_provider" {
  type        = bool
  description = "Whether to create the GitHub OIDC provider (set to false if account already has it)"
  default     = false
}

