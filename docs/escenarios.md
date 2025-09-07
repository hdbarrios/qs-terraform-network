# Resumen

- Entrada: siempre controlada por el ELB/ALB público.
- Salida: solo si se activa NAT, de lo contrario los pods quedan aislados.
- Seguridad: mantener todo privado sin NAT da máxima seguridad y cero costos extra.

## Escenario 1 – Solo red privada, ELB/ALB recibe tráfico

```bash
Internet
   |
   v
   ELB/ALB público  <---> DNS de tus URLs
           |
           v
     Subnet privada (EKS Nodes)
           |
           v
      Pods / Servicios

```

Notas:

- Entrada: ELB/ALB → pods, funciona perfectamente. ✅
- Salida a Internet: NO existe, los pods no pueden salir. ❌
- NAT/IGW: no necesarios.

## Escenario 2 – Subnet privada + NAT/IGW activa

```bash
Internet
   |
   v
   ELB/ALB público
           |
           v
     Subnet privada (EKS Nodes)
           |
           v
      Pods / Servicios
           |
           v
       NAT Gateway (en subnet pública)
           |
           v
       Internet

```

Notas:
- Entrada: igual que el escenario 1. ✅
- Salida a Internet: ahora los pods pueden salir usando la IP pública del NAT Gateway. ✅
- IGW: necesario para que el NAT Gateway pueda alcanzar Internet. ✅
