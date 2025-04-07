terraform {
  required_version = "~> 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.94"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }
  }
}

locals {
  eks_cluster_config = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    }
  }
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = local.eks_cluster_config.host
    cluster_ca_certificate = local.eks_cluster_config.cluster_ca_certificate
    exec {
      api_version = local.eks_cluster_config.exec.api_version
      command     = local.eks_cluster_config.exec.command
      args        = local.eks_cluster_config.exec.args
    }
  }
}

provider "kubernetes" {
  host                   = local.eks_cluster_config.host
  cluster_ca_certificate = local.eks_cluster_config.cluster_ca_certificate
  exec {
    api_version = local.eks_cluster_config.exec.api_version
    command     = local.eks_cluster_config.exec.command
    args        = local.eks_cluster_config.exec.args
  }
}
