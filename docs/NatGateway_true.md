# NatGateway

Este módulo de Terraform despliega una red completa en AWS con alta disponibilidad y separación de responsabilidades:

- VPC principal con subnets públicas y privadas.
- Internet Gateway (IGW) para salida/entrada a Internet desde las subnets públicas.
- NAT Gateway con Elastic IP (EIP) para que las subnets privadas accedan a Internet de forma segura.
- Route tables separadas para tráfico público y privado.
- Security Group de Odoo, con reglas de acceso parametrizables.

Para activar debe tener en la definicion de cada vpc:

`create_nat = true`


## Esquema de Red
```bash
                      +--------------------+
                      |  Internet Gateway  |
                      |        (IGW)       |
                      +---------+----------+
                                |
                                | 0.0.0.0/0
                                v
                       +---------------------+
                       |  Public Route Table |
                       +---------------------+
                          |             |
             +------------+             +------------+
             |                                       |
 +--------------------+                  +--------------------+
 | Public Subnet 1    |                  | Public Subnet 2    |
 | 10.11.30.0/24      |                  | 10.11.40.0/24      |
 | map_public_ip: true|                  | map_public_ip: true|
 +---------+----------+                  +---------+----------+
           |                                      |
           |                                      |
           v                                      v
 +--------------------+                  +--------------------+
 | NAT Gateway (EIP)  |                  | (Opcional scaling) |
 | sa-east-1a         |                  | sa-east-1b         |
 +---------+----------+                  +--------------------+
           |
           | default route
           v
                       +----------------------+
                       | Private Route Table  |
                       +----------------------+
                          |              |
             +------------+              +------------+
             |                                        |
 +---------------------+                 +---------------------+
 | Private Subnet 1    |                 | Private Subnet 2    |
 | 10.11.50.0/24       |                 | 10.11.60.0/24       |
 | map_public_ip: false|                 | map_public_ip: false|
 +---------------------+                 +---------------------+
             |                                        |
             v                                        v
   +-------------------+                    +-------------------+
   | Security Group:   |                    | Security Group:   |
   | Odoo              |                    | Odoo              |
   | - TCP 8069 ingress|                    | - SSH ingress     |
   | - Egress all      |                    | - Egress all      |
   +-------------------+                    +-------------------+
```

## Estimación de Costos (São Paulo sa-east-1)
| Recurso              | Cantidad | Costo aprox. (USD) | Costo hora | Costo día | Costo mes  |
|:---------------------|:--------:|:------------------:|:----------:|:---------:|:----------:|
| VPC                  | 1        | $0.00              | $0.00      | $0.00     | $0.00      |
| Subnets              | 4        | $0.00              | $0.00      | $0.00     | $0.00      |
| Internet Gateway     | 1        | $0.00              | $0.00      | $0.00     | $0.00      |
| Elastic IP (EIP)     | 1        | $0.005 /hora       | $0.005     | $0.12     | $3.60      |
| NAT Gateway          | 1        | $0.059 /hora       | $0.059     | $1.42     | $43.20     |
| Data transfer (salida) | depende  | ~ $0.09 /GB        | variable   | variable  | variable   |
| Security Groups      | 1        | $0.00              | $0.00      | $0.00     | $0.00      |

## Costo fijo estimado solo por red (sin instancias EC2):

Por hora: ~$0.064
Por día: ~$1.54
Por mes (30 días): ~$46.80

`Nota:` el mayor costo lo genera el NAT Gateway (unos $43/mes aprox). El resto es casi gratis, salvo el tráfico de salida a Internet que se cobra aparte.

## Conclusión:

Si tenés poco tráfico, este diseño es seguro y clásico (subnets privadas + NAT).

Si querés ahorrar, podrías eliminar el NAT Gateway y dar acceso a las instancias privadas solo con IGW + bastion host, pero perderías simplicidad y automatización.
