variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_ca_data" {
  type = string
}

variable "tags" {
  type = map(string)
}

# variable "karpenter_spot_policy_arn" {
#   type = string
# }

variable "custom_ami_id" {
  type = string
}

variable "runner_parameters" {
  type = object({
    node_pool_name = string
    max_runners    = number
  })
}

# Define a variable for namespaces and IAM group
variable "app_teams" {
  description = "List of application teams and their namespaces"
  type = list(object({
    app_name  = string
    iam_group = string
    namespace = string
    role_name = string
  }))
}
