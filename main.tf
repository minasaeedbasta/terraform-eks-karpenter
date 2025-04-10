module "eks" {
  source             = "./modules/eks"
  region             = var.region
  vpc_id             = var.vpc_id
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  karpenter_version  = var.karpenter_version
  node_group_scaling = var.node_group_scaling
  instance_type      = var.instance_type
  tags               = var.tags
}

module "karpenter" {
  source           = "./modules/karpenter"
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_data  = module.eks.cluster_ca_certificate
  tags             = var.tags
  # karpenter_spot_policy_arn = ""
  runner_parameters = var.runner_parameters
  custom_ami_id     = module.eks.custom_ami_id
  app_teams         = var.app_teams
}
