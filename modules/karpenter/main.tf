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
    cluster_name = var.cluster_name
  }
}

resource "kubernetes_manifest" "nodepool_default" {
  manifest   = yamldecode(data.template_file.nodepool_default.rendered)
  depends_on = [kubernetes_manifest.ec2nodeclass]
}

data "template_file" "nodepool_runners" {
  template = file("${path.module}/templates/nodepool_runners.tpl")
  vars = {
    node_pool_name = var.runner_parameters.node_pool_name
    max_runners    = var.runner_parameters.max_runners
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
  for_each = { for app in var.app_teams : app.app_name => app }

  metadata {
    name = each.value.namespace
  }
}

######################################
# Fetch IAM Users from Existing Group #
######################################

resource "aws_iam_policy" "eks_access_policy" {
  for_each = { for app in var.app_teams : app.app_name => app }

  name        = "eks-${each.value.app_name}-access-policy"
  description = "Access to Kubernetes API for namespace management"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "eks:AccessKubernetesApi"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "eks_group_policy_attachment" {
  for_each = { for app in var.app_teams : app.app_name => app }

  group      = each.value.iam_group
  policy_arn = aws_iam_policy.eks_access_policy[each.key].arn
}

######################################
# EKS Access Entry for Users #
######################################
resource "aws_eks_access_entry" "user_access_entry" {
  for_each = {
    for entry in local.app_users : "${entry.app_name}-${basename(entry.user_arn)}" => entry
  }

  principal_arn     = each.value.user_arn
  kubernetes_groups = [each.value.app_name]
  cluster_name      = var.cluster_name
}

######################################
# EKS Access Policy Association for Users #
######################################
resource "aws_eks_access_policy_association" "user_access_policy_association" {
  for_each = {
    for entry in local.app_users : "${entry.app_name}-${basename(entry.user_arn)}" => entry
  }

  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value.user_arn

  access_scope {
    type       = "namespace"
    namespaces = [each.value.namespace]
  }

  depends_on = [aws_eks_access_entry.user_access_entry]
}
