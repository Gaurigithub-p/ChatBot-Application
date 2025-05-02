# Data source to get the VPC details
data "aws_vpc" "default" {
  default = true
}

# Data source to get the public subnets in the default VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  # Optionally, you can add filters to restrict the subnets to specific tags, etc.
}

# IAM Role for Node Group
resource "aws_iam_role" "example1" {
  name = "eks-node-group-cloud"

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

# IAM Role Policy Attachments
resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.example1.name
  depends_on = [aws_iam_role.example1]
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.example1.name
  depends_on = [aws_iam_role.example1]
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.example1.name
  depends_on = [aws_iam_role.example1]
}

# Create EKS Cluster
resource "aws_eks_cluster" "example" {
  name     = "EKS-Cluster"
  role_arn = aws_iam_role.example1.arn

  vpc_config {
    # Ensure at least two subnets are provided, fallback to 1 if there are fewer than two
    subnet_ids = length(data.aws_subnets.public.ids) >= 2 ? slice(data.aws_subnets.public.ids, 0, 2) : data.aws_subnets.public.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
  ]
}

# Create EKS Node Group
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "Node-cloud"
  node_role_arn   = aws_iam_role.example1.arn

  # Ensure at least two subnets are provided for node group, fallback to 1 if there are fewer than two
  subnet_ids      = length(data.aws_subnets.public.ids) >= 2 ? slice(data.aws_subnets.public.ids, 0, 2) : data.aws_subnets.public.ids

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t2.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}
