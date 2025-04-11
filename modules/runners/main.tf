
resource "helm_release" "actions_runner_controller" {
  name             = "arc-controller"
  namespace        = "arc-systems"
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set-controller"
  version          = "0.11.0"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
}

resource "time_sleep" "delay_before_runner_sets_destroy" {
  destroy_duration = "45s"
  create_duration  = "1s"
  depends_on       = [helm_release.actions_runner_controller]
}

resource "helm_release" "runners" {
  name             = "arc-runners-set"
  namespace        = "arc-runners"
  repository       = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart            = "gha-runner-scale-set"
  version          = "0.11.0"
  create_namespace = true
  values = [
    templatefile("${path.module}/templates/runner_set.tpl", {
      githubConfigUrl = var.runner_parameters.githubConfigUrl
      minRunners      = var.runner_parameters.minRunners
      maxRunners      = var.runner_parameters.maxRunners
      node-pool-name  = var.runner_parameters.node-pool-name
      cpu             = var.runner_parameters.cpu
      memory          = var.runner_parameters.memory
    })
  ]

  set {
    name  = "githubConfigSecret.github_app_id"
    value = data.aws_ssm_parameter.github_app_id.value
  }

  set {
    name  = "githubConfigSecret.github_app_installation_id"
    value = data.aws_ssm_parameter.github_app_installation_id.value
  }

  set {
    name  = "githubConfigSecret.github_app_private_key"
    value = data.aws_ssm_parameter.github_app_private_key.value
  }

  depends_on = [
    helm_release.actions_runner_controller,
    time_sleep.delay_before_runner_sets_destroy
  ]
}

data "aws_ssm_parameter" "github_app_id" {
  name = var.ssm_parameter_github_app_id
}

data "aws_ssm_parameter" "github_app_installation_id" {
  name = var.ssm_parameter_github_app_installation_id
}

data "aws_ssm_parameter" "github_app_private_key" {
  name = var.ssm_parameter_github_app_private_key
}
