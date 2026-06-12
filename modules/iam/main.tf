locals {
  # This flattens the semicolon-separated policies into individual attachments
  managed_policy_attachments = flatten([
    for role_key, role_val in var.roles : [
      for policy in split(";", role_val.managed_policies) : {
        role_key = role_key
        policy   = policy
      } if policy != ""
    ]
  ])
}

# 1. Create the Roles
resource "aws_iam_role" "role" {
  for_each = var.roles
  name     = "rl-${each.value.project}-${each.value.env}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = each.value.trusted_service }
      }
    ]
  })
}

# 2. Conditionally Create Custom Policies
resource "aws_iam_policy" "custom_policy" {
  for_each = { for k, v in var.roles : k => v if v.custom_policy_file != "" }
  
  name   = "pl-${each.value.project}-${each.value.env}-${each.key}-custom"
  policy = file("${path.root}/${each.value.custom_policy_file}") 
}

# 3. Attach the Custom Policies
resource "aws_iam_role_policy_attachment" "custom_attach" {
  for_each   = aws_iam_policy.custom_policy
  role       = aws_iam_role.role[each.key].name
  policy_arn = each.value.arn
}

# 4. Attach the Managed Policies (Using the flattened local list)
resource "aws_iam_role_policy_attachment" "managed_attach" {
  for_each = { for item in local.managed_policy_attachments : "${item.role_key}-${item.policy}" => item }
  
  role       = aws_iam_role.role[each.value.role_key].name
  policy_arn = each.value.policy
}

# 5. Conditionally Create Instance Profiles
resource "aws_iam_instance_profile" "profile" {
  for_each = { for k, v in var.roles : k => v if v.create_instance_profile }
  
  name = "ip-${each.value.project}-${each.value.env}-${each.key}"
  role = aws_iam_role.role[each.key].name
}