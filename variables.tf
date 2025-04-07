variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "main"
}

variable "vpc_id" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.32"
}

variable "karpenter_version" {
  type    = string
  default = "1.1.2"
}


variable "custom_ami_id" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {
    "name" = "main"
  }
}

variable "runner_set_parameters" {
  type = map(object({
    node-pool-name = string
    maxRunners     = number
  }))
}

variable "app_teams" {
  description = "List of application teams and their namespaces"
  type = list(object({
    app_name  = string
    iam_group = string
    namespace = string
    role_name = string
  }))
}
