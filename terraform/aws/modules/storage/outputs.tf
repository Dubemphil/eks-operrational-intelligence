output "telemetry_archive_bucket_name" {
  description = "Name of the S3 telemetry archive bucket"
  value       = aws_s3_bucket.telemetry_archive.id
}

output "telemetry_archive_bucket_arn" {
  description = "ARN of the S3 telemetry archive bucket"
  value       = aws_s3_bucket.telemetry_archive.arn
}

output "dlq_quarantine_bucket_name" {
  description = "Name of the S3 DLQ quarantine bucket"
  value       = aws_s3_bucket.dlq_quarantine.id
}

output "dlq_quarantine_bucket_arn" {
  description = "ARN of the S3 DLQ quarantine bucket"
  value       = aws_s3_bucket.dlq_quarantine.arn
}

output "dynamodb_audit_table_name" {
  description = "Name of the DynamoDB remediation audit table"
  value       = aws_dynamodb_table.remediation_audit.name
}

output "dynamodb_audit_table_arn" {
  description = "ARN of the DynamoDB remediation audit table"
  value       = aws_dynamodb_table.remediation_audit.arn
}

