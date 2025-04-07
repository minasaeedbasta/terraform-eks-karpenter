output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "karpenter_release_name" {
  value = helm_release.karpenter.name
}

output "private_key_pem" {
  description = "Private key in PEM format for SSH access to nodes"
  value       = tls_private_key.eks_key.private_key_pem
  sensitive   = true
}

output "custom_ami_id" {
  value = data.aws_ami.bottlerocket_eks.image_id
}
