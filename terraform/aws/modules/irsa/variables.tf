variable "environment" {
  type        = string
  description = "Environment identifier"
  default     = "dev"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider"
}

variable "robusta_namespace" {
  type        = string
  description = "Namespace where Robusta is deployed"
  default     = "robusta"
}

variable "robusta_service_account" {
  type        = string
  description = "Name of the Robusta runner Kubernetes ServiceAccount"
  default     = "robusta-runner-service-account"
}

variable "dynamodb_audit_table_arn" {
  type        = string
  description = "ARN of DynamoDB audit table"
}

variable "dlq_quarantine_bucket_arn" {
  type        = string
  description = "ARN of S3 DLQ quarantine bucket"
}

variable "telemetry_archive_bucket_arn" {
  type        = string
  description = "ARN of S3 telemetry archive bucket"
}

