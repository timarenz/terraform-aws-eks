data "aws_region" "current" {}

locals {
  common_tags = {
    environment = var.environment_name
    owner       = var.owner_name
    ttl         = var.ttl
  }
    kubeconfig = templatefile("${path.module}/templates/kubeconfig.yaml.tpl", {
    endpoint-url           = aws_eks_cluster.main.endpoint
    base64-encoded-ca-cert = aws_eks_cluster.main.certificate_authority[0].data
    cluster-name           = aws_eks_cluster.main.name
    arn                    = aws_eks_cluster.main.arn
    region                 = data.aws_region.current.name
  })
}

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
   name = "${var.name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "main" {
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  name                      = "${var.name}-eks-cluster"
  version                   = var.kubernetes_version
  role_arn                  = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids             = var.private_subnet_ids
    endpoint_public_access = true
    public_access_cidrs = var.public_access_cidr_blocks
  }
}

resource "aws_iam_role" "eks_node_group" {
  name = "${var.name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_eks_node_group" "main" {
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.eks_cni
  ]

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.name}-eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.instance_type]

  scaling_config {
    desired_size = var.worker_count
    max_size     = var.worker_count
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}