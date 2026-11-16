#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$ROOT_DIR/terraform"
REGION="${AWS_REGION:-us-east-1}"
PROJECT="${PROJECT_NAME:-ecommerce-cloud}"
export TF_VAR_project_name="$PROJECT"
export TF_VAR_aws_region="$REGION"

command -v aws >/dev/null || { echo "AWS CLI não encontrado."; exit 1; }
command -v terraform >/dev/null || { echo "Terraform não encontrado."; exit 1; }
command -v docker >/dev/null || { echo "Docker não encontrado."; exit 1; }
aws sts get-caller-identity >/dev/null

cd "$TF_DIR"
terraform init
terraform apply -auto-approve -target=aws_ecr_repository.catalog -target=aws_ecr_repository.orders

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

docker build -t "${PROJECT}-catalog:latest" "$ROOT_DIR/app/catalog"
docker tag "${PROJECT}-catalog:latest" "${REGISTRY}/${PROJECT}-catalog:latest"
docker push "${REGISTRY}/${PROJECT}-catalog:latest"

docker build -t "${PROJECT}-orders:latest" "$ROOT_DIR/app/orders"
docker tag "${PROJECT}-orders:latest" "${REGISTRY}/${PROJECT}-orders:latest"
docker push "${REGISTRY}/${PROJECT}-orders:latest"

terraform apply -auto-approve
echo
echo "Deploy concluído. URL pública:"
terraform output -raw alb_url
