# Define IAM Policy Document for EKS Cluster Role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create IAM Role for the EKS Cluster
resource "aws_iam_role" "example" {
  name               = "eks-cluster-cloud"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach the EKS Cluster Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

# Get VPC Data for the default VPC
data "aws_vpc" "default" {
  default = true
}

# Define Subnet 1 with a new CIDR block that avoids conflicts
resource "aws_subnet" "subnet_1" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.32.0/20"  # Updated CIDR block to avoid overlap
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "my-subnet-1"
  }
}

# Define Subnet 2 with existing CIDR block
resource "aws_subnet" "subnet_2" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.16.0/24"  # Existing CIDR block
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "my-subnet-2"
  }
}

# Ensure there are at least two subnets in different Availability Zones
resource "aws_eks_cluster" "example" {
  name     = "EKS_CLOUD"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.subnet_1.id,
      aws_subnet.subnet_2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy
  ]
}

# Create IAM Role for EKS Node Group
resource "aws_iam_role" "example1" {
  name = "eks-node-group-cloud"

  assume_role_policy = jsonencode({
    Statement = [ {
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

# Attach IAM Policies for EKS Node Group
resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.example1.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.example1.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.example1.name
}

# Create the EKS Node Group
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "Node-cloud"
  node_role_arn   = aws_iam_role.example1.arn
  subnet_ids      = [
    aws_subnet.subnet_1.id,
    aws_subnet.subnet_2.id
  ]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  
  instance_types = ["t2.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly
  ]
}
