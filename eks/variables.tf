variable "cluster_name" {
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
