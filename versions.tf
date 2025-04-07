# terraform {
#   required_version = "~> 1.11"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.93"
#     }
#   }
# }

# provider "aws" {
#   region = var.region
# }

# # For Public ecr
# provider "aws" {
#   alias  = "virginia"
#   region = "us-east-1"
# }

# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.main.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
#       command     = "aws"
#     }
#   }
# }

# provider "kubernetes" {
#   host                   = aws_eks_cluster.main.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
#     command     = "aws"
#   }
# }






terraform {
  required_version = "~> 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.93"
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
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.main.name]
    }
  }
}

provider "aws" {
  region = var.region
}

# AWS provider alias for accessing public ECR in us-east-1
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
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