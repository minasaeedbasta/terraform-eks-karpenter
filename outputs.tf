output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  value = module.eks.cluster_ca_certificate
}

output "karpenter_release_name" {
  value = module.eks.karpenter_release_name
}

output "private_key_pem" {
  description = "Private key in PEM format for SSH access to nodes"
  value       = module.eks.private_key_pem
  sensitive   = true
}
