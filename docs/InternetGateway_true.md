# InternetGateway_true  

```bash
                         +---------------------+
                         |   Internet Gateway  |
                         |        (IGW)        |
                         +----------+----------+
                                    |
                                    | 0.0.0.0/0
                                    v
                         +---------------------+
                         | Public Route Table  |
                         +----------+----------+
                                    |
            +-----------------------+-----------------------+
            |                                               |
+--------------------+                          +--------------------+
| Public Subnet A    |                          | Public Subnet B    |
| 10.11.1.0/24       |                          | 10.11.2.0/24       |
| AZ: us-east-1a     |                          | AZ: us-east-1b     |
| map_public_ip=true |                          | map_public_ip=true |
+--------------------+                          +--------------------+

                         +---------------------+
                         | Private Route Table |
                         +----------+----------+
                                    |
            +-----------------------+-----------------------+
            |                                               |
+--------------------+                          +--------------------+
| Private Subnet A   |                          | Private Subnet B   |
| 10.11.3.0/24       |                          | 10.11.4.0/24       |
| AZ: us-east-1a     |                          | AZ: us-east-1b     |
| map_public_ip=false|                          | map_public_ip=false|
+--------------------+                          +--------------------+

```


## VPC y subnets

Se va a crear 1 VPC: vpc-nube con CIDR 10.11.0.0/16.

### Subnets privadas:
privated_nube1: 10.11.10.0/24 en sa-east-1a
privated_nube2: 10.11.20.0/24 en sa-east-1b
Subnets públicas (por ahora sin mapeo de IP pública, map_public_ip = false):
public_nube1: 10.11.30.0/24 en sa-east-1a
public_nube2: 10.11.40.0/24 en sa-east-1b

`Nota:` Aunque no habra salida “pública”, todavía no salida al mundo porque map_public_ip está en false.
        Igual hay IGW, así que podrías activarlas más adelante si querés IP públicas.

### Gateways y tablas de rutas

Internet Gateway: Se va a crear (vpc-nube-igw) porque create_igw = true.

### Route Tables:

private: tiene una ruta default a 0.0.0.0/0 (aunque no apunta a NAT, porque create_nat = false).
public: tiene una ruta default a la IGW.
Asociaciones: cada subnet tiene su tabla de rutas correspondiente (private o public).

## Security Group para Odoo

### odoo_secgroup con reglas:
HTTP 80 y HTTPS 443 abiertos a todos (0.0.0.0/0)
SSH 50022 abierto a todos
SSH VPN 22 solo desde 10.11.0.0/24
Además, hay un par de reglas “All IPv4/IPv6” (aparentemente default, igual no hacen mucho).

## Outputs

VPCs
Subnets
Security Groups

## Estimado de gasto:
VPC principal (10.11.0.0/16)
2 subnets privadas (AZ-a y AZ-b) → hoy no tienen salida a Internet porque no hay NAT Gateway.
2 subnets públicas (AZ-a y AZ-b) → están conectadas al Internet Gateway, pero si las instancias no tienen public_ip = true, tampoco salen afuera.

### Estimación de costos aproximados en AWS (us-east-1 / sa-east-1):
VPC, subnets, route tables, IGW → USD 0 (la red no cuesta).
EIP: si no está asociado a un recurso corriendo, cuesta ~0.005 USD/hora (≈ 3.6 USD/mes).
NAT Gateway: ~0.059 USD/hora (≈ 42 USD/mes) + tráfico (0.045 USD/GB).
Internet Gateway: gratuito, solo se paga el tráfico.
Instancias EC2: depende del tipo, por ej. una t3.micro on-demand ~0.0114 USD/h (≈ 8 USD/mes).

### Es decir:

Solo con IGW: gratis.
Si se activa NAT Gateway: mínimo 45 USD/mes sin contar tráfico.
EC2 aparte, según lo que se inicie.
