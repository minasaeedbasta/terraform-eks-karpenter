
module "eks" {
  source        = "./eks"
  vpc_id        = var.vpc_id
  custom_ami_id = var.custom_ami_id
}

module "karpenter" {
  source           = "./karpenter"
  cluster_name     = aws_eks_cluster.main.name
  cluster_endpoint = aws_eks_cluster.main.endpoint
  cluster_ca_data  = aws_eks_cluster.main.certificate_authority[0].data
  tags             = var.tags
  # karpenter_spot_policy_arn = ""
  runner_set_parameters = var.runner_set_parameters
  custom_ami_id         = var.custom_ami_id
  app_teams             = var.app_teams
}
