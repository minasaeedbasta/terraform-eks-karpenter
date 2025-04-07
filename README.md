# EKS Cluster with Karpenter Autoscaling

This Terraform project provisions an EKS cluster with a managed node group using a custom Amazon Linux 2 AMI and integrates Karpenter for workload auto-scaling.

## Prerequisites
- AWS CLI configured with credentials.
- Terraform installed.
- Helm installed.
- Custom Amazon Linux 2 AMI ID.
- Subnet and VPC IDs.

## Deployment
1. Clone this repository to AWS CodeCommit:
   ```bash
   git clone <codecommit-url>
   cd eks-karpenter-terraform