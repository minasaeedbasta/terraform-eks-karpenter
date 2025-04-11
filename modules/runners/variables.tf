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

variable "ssm_parameter_github_app_id" {
  type = string
  sensitive = true
}

variable "ssm_parameter_github_app_installation_id" {
  type = string
  sensitive = true
}

variable "ssm_parameter_github_app_private_key" {
  type = string
  sensitive = true
}