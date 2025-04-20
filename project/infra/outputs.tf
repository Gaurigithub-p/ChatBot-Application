output "cluster_name" {
  value = aws_eks_cluster.chatbot.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.chatbot.endpoint
}
