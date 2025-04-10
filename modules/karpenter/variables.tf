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
    node_pool_name = string
    max_runners    = number
  })
}

variable "apps" {
  type = list(object({
    name      = string
    namespace = string
    role_arn  = string
  }))
}
