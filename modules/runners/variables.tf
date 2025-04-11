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

variable "pat_ssm_parameter_path" {
  type = string
  sensitive = true
}
