######################################################
# Outputs
######################################################
output "vpcs" {
  description = "IDs de las VPCs creadas"
  value = {
    for k, v in aws_vpc.main : k => {
      id     = v.id
      cidr   = v.cidr_block
      region = v.region
      tags   = v.tags
    }
  }
}

output "subnets" {
  description = "IDs de las subnets creadas"
  value = {
    for k, s in aws_subnet.subnets : k => {
      id                      = s.id
      cidr_block              = s.cidr_block
      az                      = s.availability_zone
      map_public_ip_on_launch = s.map_public_ip_on_launch
      vpc_id                  = s.vpc_id
      tags                    = s.tags
    }
  }
}

output "security_groups" {
  description = "Security groups con todas sus reglas"
  value = {
    for k, sg in aws_security_group.main : k => {
      id          = sg.id
      name        = sg.name
      description = sg.description
      vpc_id      = sg.vpc_id
      region      = sg.region
      tags        = sg.tags

      ingress = tolist([
        for r in aws_security_group_rule.rules_cidr :
        {
          id          = r.id
          protocol    = r.protocol
          from_port   = r.from_port
          to_port     = r.to_port
          cidr_blocks = r.cidr_blocks
          description = r.description
        } if r.security_group_id == sg.id
      ])

      egress = tolist([
        for r in aws_security_group_rule.egress_all :
        {
          id          = r.id
          protocol    = r.protocol
          from_port   = r.from_port
          to_port     = r.to_port
          cidr_blocks = r.cidr_blocks
          description = r.description
        } if r.security_group_id == sg.id
      ])

      remote_rules = tolist([
        for r in aws_security_group_rule.rules_sg :
        {
          id                       = r.id
          protocol                 = r.protocol
          from_port                = r.from_port
          to_port                  = r.to_port
          source_security_group_id = r.source_security_group_id
          description              = r.description
        } if r.security_group_id == sg.id
      ])
    }
  }
}

