output "provider_arn" {
  description = "GitHub OIDC provider ARN (created or derived)."
  value       = local.provider_arn
}

output "role_arns" {
  description = "Map of role name to ARN."
  value       = { for name, role in aws_iam_role.deploy : name => role.arn }
}
