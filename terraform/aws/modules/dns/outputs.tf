output "zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Route 53 Nameservers to configure at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "acm_certificate_arn" {
  description = "ACM Wildcard Certificate ARN"
  value       = aws_acm_certificate.wildcard.arn
}

output "external_dns_role_arn" {
  description = "IRSA Role ARN for ExternalDNS"
  value       = aws_iam_role.external_dns.arn
}
