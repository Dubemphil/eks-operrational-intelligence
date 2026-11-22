variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
}

variable "account_id" {
  type        = string
  description = "AWS Account ID for globally unique bucket naming"
}

