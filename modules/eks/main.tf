# ##################################################
# NETWORKING AND VPC CONFIGURATION
# ##################################################

resource "aws_ec2_tag" "tag_private_subnets_discovery" {
  for_each    = toset(data.aws_subnets.private_subnets.ids)
  resource_id = each.key
  key         = "karpenter.sh/discovery"
  value       = local.cluster_name
}

resource "aws_ec2_tag" "tag_private_subnets_alb" {
  for_each    = toset(data.aws_subnets.private_subnets.ids)
  resource_id = each.key
  key         = "kubernetes.io/role/internal-elb"
  value       = 1
}

resource "aws_ec2_tag" "tag_public_subnets_alb" {
  for_each    = toset(data.aws_subnets.public_subnets.ids)
  resource_id = each.key
  key         = "kubernetes.io/role/elb"
  value       = 1
}

resource "aws_security_group" "cluster" {
  name_prefix            = "${local.cluster_name}-cluster-"
  description            = "EKS cluster security group"
  vpc_id                 = data.aws_vpc.selected.id
  revoke_rules_on_delete = false

  tags = var.tags
}

resource "aws_security_group" "node" {
  name_prefix            = "${local.cluster_name}-node-"
  description            = "EKS node shared security group"
  vpc_id                 = data.aws_vpc.selected.id
  revoke_rules_on_delete = false

  tags = {
    Name                                          = "${local.cluster_name}-node"
    Example                                       = "${local.cluster_name}"
    GithubOrg                                     = "terraform-aws-modules"
    GithubRepo                                    = "terraform-aws-eks"
    "karpenter.sh/discovery"                      = "${local.cluster_name}"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "ingress_nodes_to_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node.id
  description              = "Node groups to cluster API"
}

resource "aws_security_group_rule" "cluster_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Allow all egress from cluster"
  security_group_id = aws_security_group.cluster.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Cluster API to node groups"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  description              = "Cluster API to node kubelets"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_self_coredns_tcp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  description       = "Node to node CoreDNS TCP"
  security_group_id = aws_security_group.node.id
  self              = true
}

resource "aws_security_group_rule" "ingress_self_coredns_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  description       = "Node to node CoreDNS UDP"
  security_group_id = aws_security_group.node.id
  self              = true
}

resource "aws_security_group_rule" "ingress_nodes_ephemeral" {
  type              = "ingress"
  from_port         = 1025
  to_port           = 65535
  protocol          = "tcp"
  description       = "Node to node ingress on ephemeral ports"
  security_group_id = aws_security_group.node.id
  self              = true
}

resource "aws_security_group_rule" "ingress_cluster_4443_webhook" {
  type                     = "ingress"
  from_port                = 4443
  to_port                  = 4443
  protocol                 = "tcp"
  description              = "Cluster API to node 4443/tcp webhook"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_6443_webhook" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  description              = "Cluster API to node 6443/tcp webhook"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_8443_webhook" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  description              = "Cluster API to node 8443/tcp webhook"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "ingress_cluster_9443_webhook" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  description              = "Cluster API to node 9443/tcp webhook"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.cluster.id
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "Allow all egress"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ##################################################
# SSH KEY PAIR
# ##################################################

resource "tls_private_key" "eks_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "eks_key" {
  key_name   = "${local.cluster_name}-key"
  public_key = tls_private_key.eks_key.public_key_openssh
}

# ##################################################
# EKS CLUSTER CORE
# ##################################################

resource "random_id" "suffix" {
  byte_length = 2 # Generates an 4-character hexadecimal string
}

resource "aws_eks_cluster" "main" {
  name                      = local.cluster_name
  role_arn                  = aws_iam_role.this.arn
  version                   = var.cluster_version
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  kubernetes_network_config {
    ip_family = "ipv4"
  }

  vpc_config {
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = ["0.0.0.0/0"]

    subnet_ids         = data.aws_subnets.private_subnets.ids
    security_group_ids = [aws_security_group.cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.custom,
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.vpc_controller
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  preserve                    = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    tolerations = [{
      key    = "karpenter.sh/controller"
      value  = "true"
      effect = "NoSchedule"
    }]
  })

  depends_on = [
    aws_eks_node_group.karpenter,
    aws_iam_role_policy_attachment.custom,
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.vpc_controller
  ]
}
resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "eks-pod-identity-agent"
  preserve                    = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    agent = {
      additionalArgs = {
        "-b" = "169.254.170.23"
      }
    }
  })

  depends_on = [
    aws_eks_node_group.karpenter,
    aws_iam_role_policy_attachment.custom,
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.vpc_controller
  ]
}

resource "aws_eks_addon" "this" {
  for_each                    = toset(["vpc-cni", "kube-proxy"])
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.value
  preserve                    = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.karpenter,
    aws_iam_role_policy_attachment.custom,
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.vpc_controller
  ]
}

resource "aws_eks_access_entry" "cluster_creator_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = local.caller_arn
  type          = "STANDARD"

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_access_policy_association" "cluster_creator_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.cluster_creator_admin.principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_creator_admin]
}

resource "time_sleep" "this" {
  create_duration = "30s"
  depends_on      = [aws_eks_cluster.main]

  triggers = {
    cluster_name                       = aws_eks_cluster.main.name
    cluster_endpoint                   = aws_eks_cluster.main.endpoint
    cluster_version                    = var.cluster_version
    cluster_certificate_authority_data = aws_eks_cluster.main.certificate_authority[0].data
    cluster_service_cidr               = aws_eks_cluster.main.kubernetes_network_config[0].service_ipv4_cidr
  }
}

# ##################################################
# EKS CLUSTER IAM ROLES AND POLICIES
# ##################################################

resource "aws_iam_policy" "custom" {
  name_prefix = "${local.cluster_name}-cluster-"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Compute"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/eks:eks-cluster-name" = "$${aws:PrincipalTag/eks:eks-cluster-name}"
          }
          StringLike = {
            "aws:RequestTag/eks:kubernetes-node-class-name" = "*"
            "aws:RequestTag/eks:kubernetes-node-pool-name"  = "*"
          }
        }
      },
      {
        Sid    = "Storage"
        Effect = "Allow"
        Action = [
          "ec2:CreateVolume",
          "ec2:CreateSnapshot"
        ]
        Resource = [
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:snapshot/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestTag/eks:eks-cluster-name" = "$${aws:PrincipalTag/eks:eks-cluster-name}"
          }
        }
      },
      {
        Sid      = "Networking"
        Effect   = "Allow"
        Action   = "ec2:CreateNetworkInterface"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/eks:eks-cluster-name"         = "$${aws:PrincipalTag/eks:eks-cluster-name}"
            "aws:RequestTag/eks:kubernetes-cni-node-name" = "*"
          }
        }
      },
      {
        Sid    = "LoadBalancer"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateListener",
          "ec2:CreateSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/eks:eks-cluster-name" = "$${aws:PrincipalTag/eks:eks-cluster-name}"
          }
        }
      },
      {
        Sid      = "ShieldProtection"
        Effect   = "Allow"
        Action   = "shield:CreateProtection"
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/eks:eks-cluster-name" = "$${aws:PrincipalTag/eks:eks-cluster-name}"
          }
        }
      },
      {
        Sid      = "ShieldTagResource"
        Effect   = "Allow"
        Action   = "shield:TagResource"
        Resource = "arn:aws:shield::*:protection/*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/eks:eks-cluster-name" = "$${aws:PrincipalTag/eks:eks-cluster-name}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "this" {
  name_prefix = "cluster-role-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSClusterAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
  force_detach_policies = true
  max_session_duration  = 3600

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "custom" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.custom.arn
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "vpc_controller" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ##################################################
# OIDC AND AUTHENTICATION
# ##################################################

data "tls_certificate" "main" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.main.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.main.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "aws-node" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "aws-node"
}

# ##################################################
# KARPENTER CONFIGURATION
# ##################################################

resource "helm_release" "karpenter" {
  name                = "karpenter"
  namespace           = "karpenter"
  create_namespace    = true
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = var.karpenter_version
  wait                = false

  values = [
    <<-EOT
    nodeSelector:
      karpenter.sh/controller: 'true'
    settings:
      clusterName: ${aws_eks_cluster.main.name}
      clusterEndpoint: ${aws_eks_cluster.main.endpoint}
      # interruptionQueue: ${aws_sqs_queue.this.name}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - key: karpenter.sh/controller
        operator: Exists
        effect: NoSchedule
    webhook:
      enabled: false
    EOT
  ]

  lifecycle {
    ignore_changes = [
      repository_password
    ]
  }

  depends_on = [
    aws_eks_node_group.karpenter,
    aws_eks_access_entry.cluster_creator_admin,
    aws_eks_access_policy_association.cluster_creator_admin
  ]
}


data "template_file" "karpenter_userdata" {
  template = file("${path.module}/userdata.tpl")

  vars = {
    cluster_name = local.cluster_name
    api_server   = aws_eks_cluster.main.endpoint
    cluster_ca   = aws_eks_cluster.main.certificate_authority[0].data
  }
}


resource "aws_launch_template" "karpenter" {
  name_prefix            = "karpenter-launch-template-"
  description            = "Custom launch template for karpenter EKS managed node group"
  update_default_version = true
  image_id               = data.aws_ami.bottlerocket_eks.image_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.eks_key.key_name

  user_data = base64encode(data.template_file.karpenter_userdata.rendered)

  network_interfaces {
    security_groups       = [aws_security_group.node.id]
    delete_on_termination = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "karpenter"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "karpenter"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_eks_node_group" "karpenter" {
  cluster_name           = aws_eks_cluster.main.name
  node_group_name_prefix = "karpenter-"
  node_role_arn          = aws_iam_role.node_group.arn
  subnet_ids             = data.aws_subnets.private_subnets.ids

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  labels = {
    "karpenter.sh/controller" = "true"
  }

  taint {
    key    = "karpenter.sh/controller"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  launch_template {
    id      = aws_launch_template.karpenter.id
    version = aws_launch_template.karpenter.latest_version
  }

  update_config {
    max_unavailable_percentage = 33
  }

  tags = var.tags

  depends_on = [
    aws_eks_cluster.main,
    aws_launch_template.karpenter,
    aws_iam_role_policy_attachment.controller,
    aws_iam_role_policy_attachment.node_group,
    time_sleep.this
  ]
}

# ##################################################
# KARPENTER IAM ROLES AND POLICIES
# ##################################################

#----------------------------------------------------------#
# KARPENTER CONTROLLER (IRSA + IAM ROLE + POLICY)
#----------------------------------------------------------#

resource "aws_iam_policy" "controller" {
  name_prefix = "KarpenterController-"
  path        = "/"
  description = "Karpenter controller IAM policy"
  policy      = data.aws_iam_policy_document.v1.json

  tags = var.tags
}

resource "aws_iam_role" "controller" {
  name_prefix = "KarpenterController-"
  path        = "/"
  description = "Karpenter controller IAM role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "controller" {
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller.arn
}

resource "aws_eks_pod_identity_association" "karpenter" {
  cluster_name    = local.cluster_name
  namespace       = "karpenter"
  service_account = "karpenter"
  role_arn        = aws_iam_role.controller.arn

  tags = var.tags

  depends_on = [time_sleep.this]
}

#----------------------------------------------------------#
# KARPENTER NODE Group IAM ROLE + POLICY ATTACHMENTS
#----------------------------------------------------------#

resource "aws_iam_role" "node_group" {
  name_prefix = "karpenter-eks-node-group-"
  path        = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EKSNodeAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group" {
  for_each = {
    "AmazonEC2ContainerRegistryReadOnly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    "AmazonEKSWorkerNodePolicy"          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "AmazonEKS_CNI_Policy"               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  role       = aws_iam_role.node_group.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "node_group" {
  name_prefix = "eks-"
  path        = "/"
  role        = aws_iam_role.node_group.name

  tags = var.tags
}

resource "aws_eks_access_entry" "node_group" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.node_group.arn
  type          = "EC2_LINUX"

  tags = var.tags

  depends_on = [aws_sqs_queue.this]
}

#----------------------------------------------------------#
# KARPENTER NODE IAM ROLE
#----------------------------------------------------------#

resource "aws_iam_role" "karpenter_nodes" {
  name = local.cluster_name
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_nodes" {
  for_each = {
    "AmazonEKSWorkerNodePolicy"          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "AmazonEKS_CNI_Policy"               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    "AmazonEC2ContainerRegistryReadOnly" = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    "AmazonSSMManagedInstanceCore"       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  role       = aws_iam_role.karpenter_nodes.name
  policy_arn = each.value
}

resource "aws_eks_access_entry" "karpenter_nodes" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.karpenter_nodes.arn
  type          = "EC2_LINUX"

  tags = var.tags

  depends_on = [aws_sqs_queue.this]
}

resource "aws_iam_instance_profile" "karpenter_nodes" {
  name_prefix = "${local.cluster_name}-"
  path        = "/"
  role        = aws_iam_role.karpenter_nodes.name

  tags = var.tags
}


# ##################################################
# EVENT HANDLING AND SQS FOR KARPENTER
# ##################################################

resource "aws_sqs_queue" "this" {
  name = "${local.cluster_name}-karpenter-queue"
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each       = local.event_rules
  name_prefix    = each.value.name_prefix
  description    = each.value.description
  event_pattern  = jsonencode(each.value.event_pattern)
  event_bus_name = "default"
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = aws_cloudwatch_event_rule.this

  rule      = each.value.name
  arn       = aws_sqs_queue.this.arn
  target_id = "${each.key}-target"
}

resource "aws_sqs_queue_policy" "this_policy" {
  queue_url = aws_sqs_queue.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for rule in aws_cloudwatch_event_rule.this : {
        Sid       = "Allow-${rule.name}"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.this.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = rule.arn
          }
        }
      }
    ]
  })
}
