#############################################
# Templated Karpenter NodeClass & NodePools #
#############################################

data "template_file" "ec2nodeclass" {
  template = file("${path.module}/templates/ec2nodeclass.tpl")
  vars = {
    cluster_name  = var.cluster_name
    role          = var.cluster_name
    custom_ami_id = var.custom_ami_id
    api_server    = var.cluster_endpoint
    cluster_ca    = var.cluster_ca_data
  }
}

resource "kubernetes_manifest" "ec2nodeclass" {
  manifest = yamldecode(data.template_file.ec2nodeclass.rendered)
}

data "template_file" "nodepool_default" {
  template = file("${path.module}/templates/nodepool_default.tpl")
  vars = {
    cluster_name  = var.cluster_name
    instance_type = var.default_nodepool_instance_type
  }
}

resource "kubernetes_manifest" "nodepool_default" {
  manifest   = yamldecode(data.template_file.nodepool_default.rendered)
  depends_on = [kubernetes_manifest.ec2nodeclass]
}

data "template_file" "nodepool_runners" {
  template = file("${path.module}/templates/nodepool_runners.tpl")

  vars = {
    instance_type  = var.runner_nodepool_instance_type
    minRunners     = var.runner_parameters.maxRunners
    maxRunners     = var.runner_parameters.maxRunners
    node-pool-name = var.runner_parameters.node-pool-name
    cpu            = var.runner_parameters.cpu
    memory         = var.runner_parameters.memory
  }
}

resource "kubernetes_manifest" "nodepool_runners" {
  manifest   = yamldecode(data.template_file.nodepool_runners.rendered)
  depends_on = [kubernetes_manifest.ec2nodeclass]
}

#######################
# Namespaces for Apps #
#######################

resource "kubernetes_namespace" "app_namespace" {
  for_each = { for app in var.apps : app.name => app }

  metadata {
    name = each.value.namespace
  }
}

#####################################
# EKS Access Entry for App IAM Role #
#####################################
resource "aws_eks_access_entry" "role_access_entry" {
  for_each = { for app in var.apps : app.name => app }

  principal_arn = each.value.role_arn
  cluster_name  = var.cluster_name
}

##################################################
# EKS Access Policy Association for App IAM Role #
##################################################
resource "aws_eks_access_policy_association" "role_access_policy_association" {
  for_each = { for app in var.apps : app.name => app }

  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value.role_arn

  access_scope {
    type       = "namespace"
    namespaces = [each.value.namespace]
  }

  depends_on = [aws_eks_access_entry.role_access_entry]
}
