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

variable "custom_ami_id" {
  type = string
}

variable "runner_parameters" {
  type = object({
    githubConfigUrl = string
    minRunners      = number
    maxRunners      = number
    node-pool-name  = string
    cpu             = string
    memory          = string
  })
}

variable "default_nodepool_instance_type" {
  type = string
}

variable "runner_nodepool_instance_type" {
  type = string
}

variable "apps" {
  type = list(object({
    name      = string
    namespace = string
    role_arn  = string
  }))
}
