output "github_deployer_role_arn" {
  description = "ARN of the IAM role for GitHub Actions CI/CD"
  value       = aws_iam_role.github_deployer.arn
}

