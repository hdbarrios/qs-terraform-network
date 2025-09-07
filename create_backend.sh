#!/bin/bash
#
# Script para crear backend S3 + DynamoDB para Terraform
# ./create_backend.sh profile=qs-terraform bucket=qs-terraform-states table=terraform-iam-locks region=us-east-1

# --------------------------------------
# Valores por defecto
# --------------------------------------
profile="qs-terraform"
bucket="qs-terraform-states"
table="terraform-networks-locks"
region="us-east-1"

# --------------------------------------
# Leer flags key=value
# --------------------------------------
for arg in "$@"; do
  case $arg in
    profile=*) profile="${arg#*=}" ;;
    bucket=*)  bucket="${arg#*=}" ;;
    table=*)   table="${arg#*=}" ;;
    region=*)  region="${arg#*=}" ;;
    *) echo "⚠️ Opción desconocida: $arg"; exit 1 ;;
  esac
done

echo "Usando profile=$profile bucket=$bucket table=$table region=$region"

# --------------------------------------
# Validar AWS CLI
# --------------------------------------
if ! command -v aws &> /dev/null; then
  echo "AWS CLI no encontrado, instalando..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
  aws --version
fi

# --------------------------------------
# Crear bucket si no existe
# --------------------------------------
if aws s3api head-bucket --bucket "$bucket" --profile "$profile" &> /dev/null; then
  echo "✅ Bucket $bucket ya existe, saltando creación"
else
  echo "Creando bucket $bucket..."
  aws s3api create-bucket \
    --bucket "$bucket" \
    --region "$region" \
    --profile "$profile"
  echo "✅ Bucket $bucket creado"
fi

# --------------------------------------
# Crear tabla DynamoDB si no existe
# --------------------------------------
if aws dynamodb describe-table --table-name "$table" --region "$region" --profile "$profile" &> /dev/null; then
  echo "✅ Tabla $table ya existe en la región $region, saltando creación"
else
  echo "Creando tabla DynamoDB $table en la región $region..."
  aws dynamodb create-table --profile "$profile" --region "$region" \
    --table-name "$table" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

  echo "Esperando a que la tabla esté activa..."
  aws dynamodb wait table-exists --table-name "$table" --region "$region" --profile "$profile"

  echo "✅ Tabla $table creada y activa en la región $region"
fi

echo "Backend listo para usar"

