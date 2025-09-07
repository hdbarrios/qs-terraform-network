######################################################
# VPCs
######################################################
resource "aws_vpc" "main" {
  for_each = { for v in var.vpcs : v.name => v }

  cidr_block           = each.value.cidr
  region               = each.value.region
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

  vpc_id                  = aws_vpc.main[each.value.vpc_name].id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
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

#################################################
# Internet Gateway
#################################################
resource "aws_internet_gateway" "igw" {
  for_each = { for k, v in aws_vpc.main : k => v if try(v.create_igw, false) }

  vpc_id = each.value.id

  tags = {
    Name = "${each.key}-igw"
  }
}

#################################################
# NAT Gateways y EIPs
#################################################
resource "aws_eip" "nat" {
  for_each = { for k, v in aws_vpc.main : k => v if try(v.create_nat, false) }

  tags = {
    Name = "${each.key}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each = { for k, v in aws_vpc.main : k => v if try(v.create_nat, false) }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.subnets["${each.key}-public_nube1"].id

  tags = {
    Name = "${each.key}-nat-gw"
  }

  depends_on = [aws_eip.nat]
}

#################################################
# Route Tables
#################################################
# Route Tables públicas
resource "aws_route_table" "public" {
  for_each = aws_vpc.main

  vpc_id = each.value.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = try(aws_internet_gateway.igw[each.key].id, null)
  }

  tags = {
    Name = "${each.key}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = {
    for k, s in aws_subnet.subnets :
    k => s if can(regex("public", k))
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[join("-", slice(split("-", each.key), 0, 2))].id
}

# Route Tables privadas
resource "aws_route_table" "private" {
  for_each = aws_vpc.main

  vpc_id = each.value.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = try(aws_nat_gateway.nat[each.key].id, null)
  }

  tags = {
    Name = "${each.key}-private-rt"
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = {
    for k, s in aws_subnet.subnets :
    k => s if can(regex("privated", k))
  }

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[join("-", slice(split("-", each.key), 0, 2))].id
}
