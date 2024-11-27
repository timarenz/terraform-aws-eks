output "kubeconfig" {
  value = local.kubeconfig
}

output "id" {
  value = aws_eks_cluster.main.id
}

output "name" {
  value = aws_eks_cluster.main.name
}

output "endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "ca_certificate" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "oidc" {
  value = aws_eks_cluster.main.identity[0].oidc[0]
}