variable "region" {
  description = "The AWS region where the resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  type        = string
  default     = "main"
  description = "The name of the EKS cluster"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the EKS cluster will be deployed"
}

variable "cluster_version" {
  type        = string
  default     = "1.32"
  description = "The version of Kubernetes to use for the EKS cluster"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "The EC2 instance type to be used for the EKS worker nodes"
}

variable "node_group_scaling" {
  type = map(number)
  default = {
    desired_capacity = 2
    max_size         = 2
    min_size         = 2
  }
  description = "Scaling configuration for the EKS node group"
}

variable "karpenter_version" {
  type        = string
  default     = "1.1.2"
  description = "The version of Karpenter to be used for dynamic node provisioning in the EKS cluster"
}

variable "tags" {
  type = map(string)
  default = {
    "name" = "main"
  }
  description = "A set of key-value tags to be associated with all resources in the cluster."
}

variable "runner_parameters" {
  type = object({
    node_pool_name = string
    max_runners    = number
  })
  description = "Configuration for the runner pool, including node pool name and max number of runners"
}

variable "app_teams" {
  type = list(object({
    app_name  = string
    iam_group = string
    namespace = string
    role_name = string
  }))
  description = "List of application teams, their namespaces, IAM groups, and associated roles"
}

variable "prefix" {
  type    = string
  default = "CIS"
}

variable "environment" {
  type    = string
  default = "Dev"
}
