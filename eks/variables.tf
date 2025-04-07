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
