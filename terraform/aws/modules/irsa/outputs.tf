output "robusta_runner_role_arn" {
  description = "ARN of the IAM role for Robusta runner"
  value       = aws_iam_role.robusta_runner.arn
}

output "otel_collector_role_arn" {
  description = "ARN of the IAM role for OpenTelemetry collector"
  value       = aws_iam_role.otel_collector.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.alb_controller.arn
}

