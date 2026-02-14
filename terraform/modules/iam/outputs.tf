output "cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.cluster.name
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.node_group.arn
}

output "node_group_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = aws_iam_role.node_group.name
}

output "bedrock_dev_view_user_arn" {
  description = "ARN of the bedrock-dev-view IAM user"
  value       = var.create_developer_user ? aws_iam_user.bedrock_dev_view[0].arn : null
}

output "bedrock_dev_view_user_name" {
  description = "Name of the bedrock-dev-view IAM user"
  value       = var.create_developer_user ? aws_iam_user.bedrock_dev_view[0].name : null
}

output "bedrock_dev_view_access_key_id" {
  description = "Access Key ID for bedrock-dev-view user"
  value       = var.create_developer_user ? aws_iam_access_key.bedrock_dev_view[0].id : null
}

output "bedrock_dev_view_secret_access_key" {
  description = "Secret Access Key for bedrock-dev-view user"
  value       = var.create_developer_user ? aws_iam_access_key.bedrock_dev_view[0].secret : null
  sensitive   = true
}

output "bedrock_dev_view_secret_arn" {
  description = "ARN of the Secrets Manager secret containing access keys"
  value       = var.create_developer_user ? aws_secretsmanager_secret.bedrock_dev_view_access_key[0].arn : null
}

