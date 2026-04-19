data "aws_iam_policy_document" "iam_assume_role" {
  for_each = var.roles
  statement {
    actions = ["sts:AssumeRole"]
    principals { 
        type = "Service" 
        identifiers = [each.value.trusted_service] 
    }
  }
}
resource "aws_iam_role" "iam_role" {
  for_each           = var.roles
  name               = "role-${var.project_code}-${var.environment}-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.iam_assume_role[each.key].json
}
locals {
  role_policies = flatten([for r_id, r_cfg in var.roles : [for p in r_cfg.managed_policies : { role_id = r_id, policy_arn = p }]])
}
resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  for_each   = { for rp in local.role_policies : "${rp.role_id}-${rp.policy_arn}" => rp }
  role       = aws_iam_role.iam_role[each.value.role_id].name
  policy_arn = each.value.policy_arn
}
resource "aws_iam_instance_profile" "iam_instance_profile" {
  for_each = var.roles
  name     = "profile-${var.project_code}-${var.environment}-${each.key}"
  role     = aws_iam_role.iam_role[each.key].name
}
output "instance_profile_names" { value = { for k, v in aws_iam_instance_profile.iam_instance_profile : k => v.name } }
output "role_arns" { value = { for k, v in aws_iam_role.iam_role : k => v.arn } }