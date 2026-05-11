# Phase 2.4: EKS cluster + Airflow and EMR on EKS node groups; OIDC for IRSA
# Phase 2.8: EMR virtual cluster attached to EKS
# TODO: Use terraform-aws-modules/eks/aws and add two node groups + emrcontainers virtual cluster
data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  enabled_cluster_log_types = ["api", "audit"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]

  tags = {
    Name = var.cluster_name
    Env  = var.env
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Node group roles and node groups - minimal placeholder; expand in Phase 2.4
resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_eks_node_group" "airflow" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "airflow"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = ["t3.medium"]
  ami_type        = "AL2_x86_64"

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 0
  }

  labels = {
    role = "airflow"
  }

  tags = {
    Name = "${var.cluster_name}-airflow"
    Env  = var.env
  }
}

resource "aws_eks_node_group" "emr" {
  count           = var.use_emr_on_eks ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "emr-spark"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.subnet_ids
  instance_types  = ["r6i.xlarge"]
  ami_type        = "AL2_x86_64"

  scaling_config {
    desired_size = 0
    max_size     = 5
    min_size     = 0
  }

  labels = {
    role = "spark"
  }

  tags = {
    Name = "${var.cluster_name}-emr"
    Env  = var.env
  }
}

# OIDC for IRSA
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EMR on EKS virtual cluster (Phase 2.8)
resource "aws_emrcontainers_virtual_cluster" "main" {
  count = var.use_emr_on_eks ? 1 : 0

  name = "${var.cluster_name}-emr"
  container_provider {
    id   = aws_eks_cluster.main.name
    type = "EKS"
    info {
      eks_info {
        namespace = "emr"
      }
    }
  }
  tags = {
    Env = var.env
  }
}
