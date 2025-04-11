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
