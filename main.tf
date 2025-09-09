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
        for sn_name, sn in vpc.subnets : merge(sn, { vpc_name = vpc.name, vpc_region = vpc.region, sn_name = sn_name })
      ]
    ]) : "${subnet.vpc_name}-${subnet.sn_name}" => subnet
  }

  vpc_id                  = aws_vpc.main[each.value.vpc_name].id
  region                  = each.value.vpc_region
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = try(each.value.map_public_ip, false)

  tags = merge( var.tags,
    { Name = "${each.value.vpc_name}-${each.value.sn_name}" },
    try(each.value.tags, {})
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
  region      = each.value.region

  tags = merge( var.tags,
    { Name = each.value.name },
    try(each.value.tags, {})
  )
}

######################################################
# Security Group Rules
######################################################
resource "aws_security_group_rule" "rules_cidr" {
  for_each = {
    for rule in flatten([
      for sg in var.security_groups : [
        for rk, r in sg.rules : merge(
          r,
          {
            sg_name          = sg.name
            sg_region        = sg.region
            rk               = rk
            cidr_blocks      = try(r.cidr_blocks, [])
            ipv6_cidr_blocks = try(r.ipv6_cidr_blocks, [])
            remote_group     = try(r.remote_group, null)
          }
        )
      ]
    ]) : "${rule.sg_name}-${rule.rk}" => rule
    if (length(rule.cidr_blocks) > 0 || length(rule.ipv6_cidr_blocks) > 0) && rule.remote_group == null
  }

  type              = try(each.value.direction, "ingress")
  protocol          = each.value.protocol == "all" ? "-1" : each.value.protocol
  from_port         = each.value.protocol == "all" ? 0 : lookup(each.value, "port_from", each.value.port[0])
  to_port           = each.value.protocol == "all" ? 0 : lookup(each.value, "port_to", each.value.port[0])
  cidr_blocks       = each.value.cidr_blocks
  ipv6_cidr_blocks  = each.value.ipv6_cidr_blocks
  security_group_id = aws_security_group.main[each.value.sg_name].id
  description       = try(each.value.description, "Rule ${each.value.rk}")
  region            = each.value.sg_region

}

resource "aws_security_group_rule" "rules_sg" {
  for_each = {
    for rule in flatten([
      for sg in var.security_groups : [
        for rk, r in sg.rules : merge(
          r,
          {
            sg_name          = sg.name
            sg_region        = sg.region
            rk               = rk
            remote_group     = try(r.remote_group, null)
          }
        )
      ]
    ]) : "${rule.sg_name}-${rule.rk}" => rule
    if rule.remote_group != null
  }

  type                     = try(each.value.direction, "ingress")
  protocol                 = each.value.protocol == "all" ? "-1" : each.value.protocol
  from_port                = each.value.protocol == "all" ? 0 : lookup(each.value, "port_from", each.value.port[0])
  to_port                  = each.value.protocol == "all" ? 0 : lookup(each.value, "port_to", each.value.port[0])
  source_security_group_id = lookup(aws_security_group.main, each.value.remote_group, null).id
  security_group_id        = aws_security_group.main[each.value.sg_name].id
  description              = try(each.value.description, "Rule ${each.value.rk}")
  region                   = each.value.sg_region
}

# Reglas de salida (egress) para todos los Security Groups
resource "aws_security_group_rule" "egress_all" {
  for_each = { for sg in var.security_groups : sg.name => sg }

  type              = "egress"
  protocol          = "-1"  # 'all'
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.main[each.value.name].id
  description       = "Salida a internet"
  region            = each.value.region
}


#################################################
# Internet Gateway
#################################################
resource "aws_internet_gateway" "igw" {
  for_each = { for v in var.vpcs : v.name => v if try(v.create_igw, false) }

  vpc_id = aws_vpc.main[each.key].id  # <-- ahora sí usamos el ID del recurso creado
  region                  = each.value.region


  tags = merge( var.tags,
   { Name = "${each.key}-igw" },
   try(each.value.tags, {})
  )
}

#################################################
# NAT Gateways y EIPs
#################################################
resource "aws_eip" "nat" {
  for_each = { for v in var.vpcs : v.name => v if try(v.create_nat, false) }

  tags = merge( var.tags,
   { Name = "${each.key}-nat-eip"},
   try(each.value.tags, {})
  )
}

resource "aws_nat_gateway" "nat" {
  for_each = { for v in var.vpcs : v.name => v if try(v.create_nat, false) }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.subnets["${each.key}-public_nube1"].id
  region = each.value.region

  tags = merge( var.tags,
   { Name = "${each.key}-nat-gw" },
   try(each.value.tags, {})
  )

  depends_on = [aws_eip.nat]
}

#################################################
# Route Tables públicas
#################################################
resource "aws_route_table" "public" {
  # Transformamos la lista de VPCs en map por nombre y filtramos las que crean IGW
  for_each = { for v in var.vpcs : v.name => v if v.create_igw }

  vpc_id = aws_vpc.main[each.key].id
  region = each.value.region

  # Ruta default solo si la VPC tiene IGW
  dynamic "route" {
    for_each = each.value.create_igw ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw[each.key].id
    }
  }

  tags = merge( var.tags,
   { Name = "${each.key}-public-rt" },
   try(each.value.tags, {})
  )
 
}

resource "aws_route_table_association" "public_assoc" {
  for_each = {
    for k, s in aws_subnet.subnets :
    k => s if can(regex("public", k)) && contains(keys(aws_route_table.public), join("-", slice(split("-", k), 0, 2)))
  }

  region         = each.value.region
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[join("-", slice(split("-", each.key), 0, 2))].id

}

# Route Tables privadas
resource "aws_route_table" "private" {
  # Transformamos la lista de VPCs en map por nombre y filtramos las que crean NAT
  for_each = { for v in var.vpcs : v.name => v if v.create_nat }

  vpc_id = aws_vpc.main[each.key].id
  region = each.value.region

  # Ruta default solo si la VPC tiene NAT
  dynamic "route" {
    for_each = each.value.create_nat ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.nat[each.key].id
    }
  }

  tags = merge(
    var.tags,
    { Name = "${each.key}-private-rt" },
    try(each.value.tags, {})
  )
}

resource "aws_route_table_association" "private_assoc" {
  for_each = {
    for k, s in aws_subnet.subnets :
    k => s if can(regex("privated", k)) && contains(keys(aws_route_table.private), join("-", slice(split("-", k), 0, 2)))
  }

  region         = each.value.region
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[join("-", slice(split("-", each.key), 0, 2))].id
}
