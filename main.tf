######################################################
# VPCs
######################################################
resource "aws_vpc" "main" {
  for_each = { for v in var.vpcs : v.name => v }

  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    { Name = each.value.name },
    try(each.value.tags, {}),
    var.tags
  )
}

######################################################
# Subnets
######################################################
resource "aws_subnet" "subnets" {
  for_each = {
    for subnet in flatten([
      for vpc in var.vpcs : [
        for sn_name, sn in vpc.subnets : merge(sn, { vpc_name = vpc.name, sn_name = sn_name })
      ]
    ]) : "${subnet.vpc_name}-${subnet.sn_name}" => subnet
  }

  vpc_id            = aws_vpc.main[each.value.vpc_name].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone
  map_public_ip_on_launch = try(each.value.map_public_ip, false)

  tags = merge(
    { Name = "${each.value.vpc_name}-${each.value.sn_name}" },
    try(each.value.tags, {}),
    var.tags
  )
}

######################################################
# Security Groups
######################################################
resource "aws_security_group" "main" {
  for_each = { for sg in var.security_groups : sg.name => sg }

  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.main[each.value.vpc].id

  tags = merge(
    { Name = each.value.name },
    try(each.value.tags, {}),
    var.tags
  )
}

######################################################
# Security Group Rules
######################################################
resource "aws_security_group_rule" "rules" {
  for_each = {
    for rule in flatten([
      for sg in var.security_groups : [
        for rk, r in sg.rules : merge(r, { sg_name = sg.name, rk = rk })
      ]
    ]) : "${rule.sg_name}-${rule.rk}" => rule
  }

  type              = try(each.value.direction, "ingress")
  protocol          = each.value.protocol == "all" ? "-1" : each.value.protocol
  from_port         = each.value.protocol == "all" ? 0 : lookup(each.value, "port_from", each.value.port[0])
  to_port           = each.value.protocol == "all" ? 0 : lookup(each.value, "port_to", each.value.port[0])
  cidr_blocks       = try(each.value.cidr_blocks, [])
  ipv6_cidr_blocks  = try(each.value.ipv6_cidr_blocks, [])
  security_group_id = aws_security_group.main[each.value.sg_name].id
  description       = try(each.value.description, "Rule ${each.value.rk}")

  source_security_group_id = try(
    each.value.remote_group != null ? aws_security_group.main[each.value.remote_group].id : null,
    null
  )
}

