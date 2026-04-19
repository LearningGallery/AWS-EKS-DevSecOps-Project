locals { base = "${var.project_code}-${var.environment}-${var.network_zone}" }

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "vp-${local.base}" }
}
resource "aws_internet_gateway" "internet_gateway" {
  count  = length([for k, v in var.subnets : v if v.is_public]) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags = { Name = "ig-${local.base}" }
}
resource "aws_subnet" "subnets" {
  for_each          = var.subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags = { Name = "sn-${local.base}-${each.value.role}-${split("-", each.value.az)[2]}", Tier = each.value.is_public ? "Public" : "Private" }
}
resource "aws_route_table" "route_table_public" {
  count  = length([for k, v in var.subnets : v if v.is_public]) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "rt-${local.base}-pub" }
}
resource "aws_route_table" "route_table_private" {
  for_each = toset([for k, v in var.subnets : v.role if !v.is_public])
  vpc_id   = aws_vpc.vpc.id
  tags     = { Name = "rt-${local.base}-${each.key}" }
}
resource "aws_route_table_association" "route_table_association" {
  for_each       = var.subnets
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = each.value.is_public ? aws_route_table.route_table_public[0].id : aws_route_table.route_table_private[each.value.role].id
}
resource "aws_route" "route" {
  for_each               = { for idx, rule in var.route_rules : "${rule.route_table_role}-${idx}" => rule }
  route_table_id         = each.value.route_table_role == "pub" ? aws_route_table.route_table_public[0].id : aws_route_table.route_table_private[each.value.route_table_role].id
  destination_cidr_block = each.value.destination_cidr
  gateway_id             = each.value.target_type == "igw" ? aws_internet_gateway.internet_gateway[0].id : null
}
resource "aws_security_group" "security_group" {
  for_each    = toset([for k, v in var.subnets : v.role])
  name        = "${local.base}-${each.key}-sg"
  vpc_id      = aws_vpc.vpc.id
  tags        = { Name = "sg-${local.base}-${each.key}" }
}
resource "aws_security_group_rule" "security_group_rule" {
  for_each                 = { for idx, rule in var.sg_rules : "${rule.sg_role}-${rule.type}-${idx}" => rule }
  security_group_id        = aws_security_group.security_group[each.value.sg_role].id
  type                     = each.value.type
  from_port                = tonumber(each.value.from_port)
  to_port                  = tonumber(each.value.to_port)
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.source_type == "cidr" ? [each.value.source] : null
  source_security_group_id = each.value.source_type == "sg" ? aws_security_group.security_group[each.value.source].id : null
}

resource "aws_network_acl" "network_acl" {
  for_each   = toset([for k, v in var.subnets : v.role])
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [for k, v in var.subnets : aws_subnet.subnets[k].id if v.role == each.key]
  tags       = { Name = "nl-${local.base}-${each.key}" }
}

resource "aws_network_acl_rule" "network_acl_rule" {
  for_each       = { for idx, rule in var.nacl_rules : "${rule.nacl_role}-${rule.type}-${rule.rule_no}" => rule }
  network_acl_id = aws_network_acl.network_acl[each.value.nacl_role].id
  rule_number    = tonumber(each.value.rule_no)
  egress         = each.value.type == "egress" ? true : false
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr_block
  from_port      = tonumber(each.value.from_port)
  to_port        = tonumber(each.value.to_port)
}