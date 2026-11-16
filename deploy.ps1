$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$Tf = Join-Path $Root "terraform"
$Region = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
$Project = if ($env:PROJECT_NAME) { $env:PROJECT_NAME } else { "ecommerce-cloud" }
$env:TF_VAR_project_name = $Project
$env:TF_VAR_aws_region = $Region

foreach ($cmd in @("aws", "terraform", "docker")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "$cmd não encontrado. Instale antes de continuar."
    }
}
aws sts get-caller-identity | Out-Null
Set-Location $Tf
terraform init
terraform apply -auto-approve -target=aws_ecr_repository.catalog -target=aws_ecr_repository.orders

$Account = aws sts get-caller-identity --query Account --output text
$Registry = "$Account.dkr.ecr.$Region.amazonaws.com"
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry

docker build -t "${Project}-catalog:latest" (Join-Path $Root "app/catalog")
docker tag "${Project}-catalog:latest" "${Registry}/${Project}-catalog:latest"
docker push "${Registry}/${Project}-catalog:latest"

docker build -t "${Project}-orders:latest" (Join-Path $Root "app/orders")
docker tag "${Project}-orders:latest" "${Registry}/${Project}-orders:latest"
docker push "${Registry}/${Project}-orders:latest"

terraform apply -auto-approve
Write-Host "Deploy concluído. URL pública:"
terraform output -raw alb_url
