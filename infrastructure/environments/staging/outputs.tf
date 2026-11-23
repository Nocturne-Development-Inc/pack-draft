output "aws_region" {
  description = "AWS region this environment targets."
  value       = var.aws_region
}

output "environment" {
  description = "Environment name."
  value       = var.environment
}

output "name_prefix" {
  description = "Shared name prefix for resources in this environment."
  value       = local.name_prefix
}
