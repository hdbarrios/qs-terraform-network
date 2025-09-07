# Terraform AWS Network Infrastructure

Este repositorio contiene scripts de **Terraform** para desplegar infraestructura de red en AWS:

- VPCs
- Subnets públicas y privadas
- Security Groups con reglas personalizadas

---

## Diagrama de la Infraestructura

```bash
                 ┌───────────────┐
                 │     VPC       │
                 │ 10.11.0.0/16  │
                 └───────┬───────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
 ┌───────────────┐                 ┌───────────────┐
 │ Private Subnet│                 │ Public Subnet │
 │ 10.11.10.0/24 │                 │ 10.11.30.0/24 │
 │ 10.11.20.0/24 │                 │ 10.11.40.0/24 │
 │ 10.11.50.0/24 │                 │               │
 └───────┬───────┘                 └───────┬───────┘
         │                                 │
 ┌───────────────┐                 ┌───────────────┐
 │ EC2 / Odoo    │                 │ ELB / NAT GW  │
 └───────────────┘                 └───────────────┘
```


- **Private Subnet**: Para instancias internas (ej. Odoo, DB)
- **Public Subnet**: Para NAT Gateway, ELB o cualquier recurso que necesite salida a Internet
- **Security Groups**: Gestionan el acceso a las instancias, con reglas definidas por `.tfvars`

---

## Estructura del Repositorio

```
.
├── main.tf # Recursos: VPC, Subnets, SG
├── variables.tf # Variables
├── outputs.tf # Outputs
├── backend.tf # Backend S3 + DynamoDB
├── profiles/
│   └── networks.tfvars # Configuración de entornos
└── .gitignore
```
---

## Uso

1. Inicializar Terraform:

```bash
terraform init -upgrade
```
2. Revisar el plan:
```bash
terraform plan -var-file=profiles/networks.tfvars
```

3. Aplicar infraestructura:
```bash
terraform apply -var-file=profiles/networks.tfvars
```

4. Destruir todo si hace falta:
```bash
terraform destroy -var-file=profiles/networks.tfvars
```

## Consideraciones

- Mantener los .tfvars fuera de Git si contienen datos sensibles
- Escalable: agregar más VPCs, subnets y reglas desde los .tfvars
- AWS Profile y región deben coincidir con los permisos de despliegue

---

## Autor

Hector Barrios – hdbarrios@gmail.com
Proyecto: Redes AWS con Terraform
