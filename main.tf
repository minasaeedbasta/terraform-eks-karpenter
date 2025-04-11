module "eks" {
  source             = "./modules/eks"
  region             = var.region
  vpc_id             = var.vpc_id
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  karpenter_version  = var.karpenter_version
  node_group_scaling = var.node_group_scaling
  instance_type      = var.instance_type
  apps               = var.apps
  cluster_admins     = var.cluster_admins
  tags               = var.tags
}

module "karpenter" {
  source                         = "./modules/karpenter"
  cluster_name                   = module.eks.cluster_name
  cluster_endpoint               = module.eks.cluster_endpoint
  cluster_ca_data                = module.eks.cluster_ca_certificate
  custom_ami_id                  = module.eks.custom_ami_id
  runner_parameters              = var.runner_parameters
  runner_nodepool_instance_type  = var.runner_nodepool_instance_type
  default_nodepool_instance_type = var.default_nodepool_instance_type
  tags                           = var.tags
}

module "runners" {
  source                                   = "./modules/runners"
  runner_parameters                        = var.runner_parameters
  ssm_parameter_github_app_id              = var.ssm_parameter_github_app_id
  ssm_parameter_github_app_installation_id = var.ssm_parameter_github_app_installation_id
  ssm_parameter_github_app_private_key     = var.ssm_parameter_github_app_private_key
}
