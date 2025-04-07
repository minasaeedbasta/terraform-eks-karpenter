
module "eks" {
  source        = "./eks"
  vpc_id        = var.vpc_id
  custom_ami_id = var.custom_ami_id
}

module "karpenter" {
  source           = "./karpenter"
  cluster_name     = var.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_data  = module.eks.cluster_ca_certificate
  tags             = var.tags
  # karpenter_spot_policy_arn = ""
  runner_set_parameters = var.runner_set_parameters
  custom_ami_id         = var.custom_ami_id
  app_teams             = var.app_teams
}
