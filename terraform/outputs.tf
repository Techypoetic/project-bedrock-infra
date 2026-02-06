# This file will be populated as we create resources
# For now, just output the region to verify Terraform works

output "region" {
  description = "AWS region"
  value       = var.region
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}
