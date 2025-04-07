locals {
  app_users = flatten([
    for app in var.app_teams : [
      for user in data.aws_iam_group.app_group[app.app_name].users : {
        app_name  = app.app_name
        user_arn  = user.arn
        namespace = app.namespace
      }
    ]
  ])
}
