# General:
aws_region                = "sa-east-1"
aws_account               = "929405966946"
aws_profile               = "qs-terraform"
availability_zones        = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
tags                      = {
    repositorio = "git@github.com:quilsoft-org/tf-network.git"
    proyecto    = "networks"
    equipo      = "SRE"
    environment = "PRD"
    autor       = "hdbarrios@gmail.com"
}

# VPC:
vpcs = [
  {
    name   = "vpc-nube"
    cidr   = "10.11.0.0/16"
    region = "sa-east-1"
    subnets = {
      privated_nube1 = { cidr = "10.11.10.0/24", availability_zone = "sa-east-1a" }
      privated_nube2 = { cidr = "10.11.20.0/24", availability_zone = "sa-east-1b" }
      public_nube1   = { cidr = "10.11.30.0/24", availability_zone = "sa-east-1a", map_public_ip = false }
      public_nube2   = { cidr = "10.11.40.0/24", availability_zone = "sa-east-1b", map_public_ip = false }
    }
    public_subnets  = ["public_nube1", "public_nube2"]
    private_subnets = ["privated_nube1", "privated_nube2"]
    create_igw = false
    create_nat = true
  }
]

# Security Groups
security_groups = [
  {
    name  = "odoo_secgroup"
    description = "Grupo de seguridad para odoo"
    vpc   = "vpc-nube"
    rules = {
      sh = {
        port        = [50022]
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Puerto ssh"
        ethertype   = "IPv4"
      },
      sshvpn = {
        port        = [22]
        protocol    = "tcp"
        cidr_blocks = ["10.11.0.0/24"]
        description = "SSH VPN"
        ethertype   = "IPv4"
      },
      ssh_vpn = {
        port        = [50022]
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Puerto ssh"
        ethertype   = "IPv4"
      },
      https = {
        port        = [443]
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Puerto HTTPS"
        ethertype   = "IPv4"
      },
      http ={
        port        = [80, 8080]
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Puerto HTTP"
        ethertype   = "IPv4"
      },
      All_IPv4 = {
        port        = [0]
        protocol    = "all"
        cidr_blocks = []
        remote_group = "odoo_secgroup"
        description  = ""
        ethertype   = "IPv4"
      },
      All_IPv6 = {
        port        = [0]
        protocol    = "all"
        cidr_blocks = []
        remote_group = "odoo_secgroup"
        description  = ""
        ethertype    = "IPv6"
      }
    }
  }
]

