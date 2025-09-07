######################################################
# Outputs
######################################################
output "vpcs" {
  description = "IDs de las VPCs creadas"
  value       = { for k, v in aws_vpc.main : k => v.id }
}

output "subnets" {
  description = "IDs de las subnets creadas"
  value       = { for k, v in aws_subnet.subnets : k => v.id }
}

output "security_groups" {
  description = "IDs de los security groups"
  value       = { for k, v in aws_security_group.main : k => v.id }
}

