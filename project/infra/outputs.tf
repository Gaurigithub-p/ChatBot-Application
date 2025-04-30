# output.tf

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_security_group_id" {
  description = "The security group ID associated with the EKS cluster"
  value       = aws_security_group.eks_security_group.id
}
