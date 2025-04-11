variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "node_group_scaling" {
  type = map(number)
}

variable "karpenter_version" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "prefix" {
  type    = string
  default = "CIS"
}

variable "environment" {
  type    = string
  default = "Dev"
}


variable "apps" {
  type = list(object({
    name      = string
    namespace = string
    role_arn  = string
  }))
}

variable "cluster_admins" {
  type = list(object({
    name     = string
    role_arn = string
  }))
}
