
##########################
# General
##########################

variable "aws_region" {
  description = "AWS Region"
  default     = "sa-east-1"
}

variable "aws_profile" {
  description = "AWS Profile"
  default     = "terraform-admin"
}

variable "profile_path" {
  default = "./profiles"
}


variable "aws_account" {
  description = "ID de cuenta AWS"
  type        = string
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad a usar"
  type        = list(string)
}

variable "tags" {
  description = "Mapa de tags comunes a aplicar a todos los recursos"
  type        = map(string)
  default     = {}
}

##########################
# VPCs
##########################
variable "vpcs" {
  type = list(object({
    name   = string
    cidr   = string
    region = string
    create_igw = bool
    create_nat = bool
    subnets = map(object({
      cidr              = string
      availability_zone = string
      map_public_ip     = optional(bool, false)
      tags              = optional(map(string), {})
    }))
  }))
}

##########################
# Security Groups
##########################
variable "security_groups" {
  description = <<EOT
Lista de security groups.  
Cada SG define un conjunto de reglas.
EOT
  type = list(object({
    name        = string
    description = string
    vpc         = string
    rules = map(object({
      port         = list(number)
      protocol     = string
      cidr_blocks  = list(string)
      description  = string
      ethertype    = string
      remote_group = optional(string)
    }))
  }))
}

