variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "create_developer_user" {
  description = "Whether to create the bedrock-dev-view IAM user"
  type        = bool
  default     = true
}

variable "developer_user_name" {
  description = "Name of the developer IAM user"
  type        = string
  default     = "bedrock-dev-view"
}
