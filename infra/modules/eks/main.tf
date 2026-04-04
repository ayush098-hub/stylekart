resource "aws_eks_cluster" "example" {
  name = var.cluster_name

  role_arn = aws_iam_role.cluster.arn
  version  = var.k8s_version

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
    subnet_ids = var.subnet_ids
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}



resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-eks-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

//worker nodes roles and policies

resource "aws_iam_role" "node-group-role" {
  name = "${var.cluster_name}-node-iam-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  role = aws_iam_role.node-group-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.node-group-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.node-group-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "worker-nodes" {
  cluster_name = aws_eks_cluster.example.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn = aws_iam_role.node-group-role.arn
  scaling_config {
    max_size = var.max_size
    min_size = var.min_size
    desired_size = var.desired_size
  }
  subnet_ids = var.subnet_ids

  instance_types = var.instance_types

  depends_on = [
    aws_iam_role_policy_attachment.worker_node,
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr
  ]
}

data "aws_caller_identity" "current" {}
