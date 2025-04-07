data "aws_iam_group" "app_group" {
  for_each = { for app in var.app_teams : app.app_name => app }

  group_name = each.value.iam_group
}
