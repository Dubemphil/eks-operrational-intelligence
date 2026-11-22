output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "telemetry_archive_bucket" {
  description = "S3 bucket for cold telemetry archive"
  value       = module.storage.telemetry_archive_bucket_name
}

output "dlq_quarantine_bucket" {
  description = "S3 bucket for DLQ quarantine"
  value       = module.storage.dlq_quarantine_bucket_name
}

output "dynamodb_audit_table" {
  description = "DynamoDB table for remediation audit trail"
  value       = module.storage.dynamodb_audit_table_name
}

output "robusta_runner_role_arn" {
  description = "IRSA Role ARN for Robusta runner"
  value       = module.irsa.robusta_runner_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IRSA Role ARN for AWS Load Balancer Controller"
  value       = module.irsa.aws_load_balancer_controller_role_arn
}

output "github_deployer_role_arn" {
  description = "Role ARN for GitHub Actions CI/CD"
  value       = var.enable_github_oidc ? module.oidc_github[0].github_deployer_role_arn : null
}

