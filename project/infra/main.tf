provider "aws" {
  region = "ap-south-1"
}

resource "aws_eks_cluster" "chatbot_eks_cluster" {
  name     = "chatbot-eks-cluster"
  role_arn = aws_iam_role.eks_service_role.arn

  vpc_config {
    subnet_ids = aws_subnet.subnet_ids[*].id
  }
}

resource "aws_iam_role" "eks_service_role" {
  name = "eks-service-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_eks_node_group" "chatbot_node_group" {
  cluster_name    = aws_eks_cluster.chatbot_eks_cluster.name
  node_group_name = "chatbot-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.subnet_ids[*].id
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
}

resource "aws_iam_role" "node_role" {
  name = "eks-node-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_subnet" "subnet_ids" {
  count = 2
  vpc_id = aws_vpc.vpc_id
  cidr_block = cidrsubnet(aws_vpc.vpc_id, 8, count.index)
}
