output "cluster_name" {
  value = var.cluster_name
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.example.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_url" {
  value = trimprefix(aws_eks_cluster.example.identity[0].oidc[0].issuer, "https://")
}

output "oidc_provider_arn" {
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${trimprefix(aws_eks_cluster.example.identity[0].oidc[0].issuer, "https://")}"
}