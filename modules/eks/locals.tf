locals {
  account_id  = data.aws_caller_identity.current.account_id
  caller_arn  = data.aws_caller_identity.current.arn
  caller_user = data.aws_caller_identity.current.user_id
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

locals {
  partition               = "aws"
  region                  = var.region
  dns_suffix              = "amazonaws.com"
  enable_spot_termination = true
}

locals {
  cluster_name = "${var.prefix}-${var.environment}-${var.cluster_name}-${random_id.suffix.hex}"
}

locals {
  event_rules = {
    spot_interrupt = {
      description = "Karpenter interrupt - EC2 spot instance interruption warning"
      event_pattern = {
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Spot Instance Interruption Warning"]
      }
      name_prefix = "KarpenterSpotInterrupt-"
    }

    instance_rebalance = {
      description = "Karpenter interrupt - EC2 instance rebalance recommendation"
      event_pattern = {
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Instance Rebalance Recommendation"]
      }
      name_prefix = "KarpenterInstanceRebalance-"
    }

    instance_state_change = {
      description = "Karpenter interrupt - EC2 instance state-change notification"
      event_pattern = {
        source        = ["aws.ec2"]
        "detail-type" = ["EC2 Instance State-change Notification"]
      }
      name_prefix = "KarpenterInstanceStateChange-"
    }

    health_event = {
      description = "Karpenter interrupt - AWS health event"
      event_pattern = {
        source        = ["aws.health"]
        "detail-type" = ["AWS Health Event"]
      }
      name_prefix = "KarpenterHealthEvent-"
    }
  }
}
