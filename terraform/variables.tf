variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "project-bedrock"
}

variable "environment" {
  description = "Environment (e.g., production, staging)"
  type        = string
  default     = "production"
}
