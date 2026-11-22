output "AWS_ROLE_ARN" {
  description = "IAM Role ARN to configure as GitHub Secret: AWS_ROLE_ARN"
  value       = aws_iam_role.github_deployer.arn
}

output "TF_STATE_BUCKET" {
  description = "S3 Bucket Name to configure as GitHub Secret: TF_STATE_BUCKET"
  value       = aws_s3_bucket.tf_state.id
}

output "TF_LOCK_TABLE" {
  description = "DynamoDB Table Name to configure as GitHub Secret: TF_LOCK_TABLE"
  value       = aws_dynamodb_table.tf_lock.name
}

output "AWS_REGION" {
  description = "AWS Region to configure as GitHub Secret: AWS_REGION"
  value       = var.aws_region
}

