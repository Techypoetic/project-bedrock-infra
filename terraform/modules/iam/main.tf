# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-role"
    }
  )
}

# Attach EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Attach EKS VPC Resource Controller Policy (for security groups)
resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node-role"
    }
  )
}

# Attach Worker Node Policy
resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

# Attach CNI Policy
resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

# Attach ECR Read Only Policy
resource "aws_iam_role_policy_attachment" "node_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# Additional policy for CloudWatch (for logging in Phase 5)
resource "aws_iam_role_policy_attachment" "node_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group.name
}

# ============================================================================
# Developer User Resources
# ============================================================================

resource "aws_iam_user" "bedrock_dev_view" {
  count = var.create_developer_user ? 1 : 0

  name = var.developer_user_name
  path = "/"

  tags = merge(
    var.tags,
    {
      Project     = "barakat-2025-capstone"
      Name        = var.developer_user_name
      Role        = "Developer"
      Access      = "ReadOnly"
      Description = "Developer user with read-only access to AWS and EKS cluster info"
    }
  )
}

resource "aws_iam_user_policy_attachment" "bedrock_dev_view_readonly" {
  count = var.create_developer_user ? 1 : 0

  user       = aws_iam_user.bedrock_dev_view[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user_policy" "bedrock_dev_view_eks_describe" {
  count = var.create_developer_user ? 1 : 0

  name = "${var.developer_user_name}-eks-describe"
  user = aws_iam_user.bedrock_dev_view[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "bedrock_dev_view" {
  count = var.create_developer_user ? 1 : 0

  user = aws_iam_user.bedrock_dev_view[0].name
}

resource "aws_secretsmanager_secret" "bedrock_dev_view_access_key" {
  count = var.create_developer_user ? 1 : 0

  name          = "${var.developer_user_name}-access-key"
  description   = "Access keys for ${var.developer_user_name} user"

  tags = merge(
    var.tags,
    {
      Project = "barakat-2025-capstone"
      Name    = "${var.developer_user_name}-access-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "bedrock_dev_view_access_key" {
  count = var.create_developer_user ? 1 : 0

  secret_id = aws_secretsmanager_secret.bedrock_dev_view_access_key[0].id
  secret_string = jsonencode({
    access_key_id     = aws_iam_access_key.bedrock_dev_view[0].id
    secret_access_key = aws_iam_access_key.bedrock_dev_view[0].secret
    user_arn          = aws_iam_user.bedrock_dev_view[0].arn
  })
}

