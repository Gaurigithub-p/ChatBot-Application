# Fetch Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create IAM Role for Worker Nodes
resource "aws_iam_role" "eks_worker_role" {
  name = "eks-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach Worker Node Policies
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create the EKS Cluster
resource "aws_eks_cluster" "chatbot" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
    endpoint_public_access = true  # Allows public access to the EKS API server
    endpoint_private_access = true # Allows private access to the EKS API server
  }
}

# Security Group for EKS Workers
resource "aws_security_group" "eks_worker_sg" {
  vpc_id = data.aws_vpc.default.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    description = "Allow HTTPS traffic"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  ingress {
    description = "Allow HTTP traffic"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  ingress {
    description = "Allow Node to Node Communication (10250)"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
  }

  ingress {
    description = "Allow NodePort Range (30000-32767)"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
  }
}

# IAM Instance Profile for Worker Nodes
resource "aws_iam_instance_profile" "eks_worker_profile" {
  name = "eks-worker-profile-${var.cluster_name}"
  role = aws_iam_role.eks_worker_role.name
}

# Launch Template for Worker Nodes
resource "aws_launch_template" "eks_worker_launch_template" {
  name_prefix   = "eks-worker-"
  image_id      = "ami-0e35ddab05955cf57"  # Update with the latest EKS-optimized AMI
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_worker_profile.name
  }

  network_interfaces {
    security_groups = [aws_security_group.eks_worker_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-worker-node"
    }
  }

  user_data = base64encode(<<-EOT
    #!/bin/bash
    /etc/eks/bootstrap.sh ${var.cluster_name} --kubelet-extra-args '--node-labels=node-role.kubernetes.io/worker=worker'
  EOT
  )
}

# AutoScaling Group for Worker Nodes
resource "aws_autoscaling_group" "eks_worker_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = data.aws_subnets.default.ids
  health_check_type    = "EC2"

  launch_template {
    id      = aws_launch_template.eks_worker_launch_template.id
    version = aws_launch_template.eks_worker_launch_template.latest_version
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}
