# E-commerce Cloud AWS

Projeto didático de arquitetura de microsserviços na AWS, provisionado com Terraform.

## 1. Arquitetura

- **Amazon VPC** com duas zonas de disponibilidade e sub-redes públicas.
- **Application Load Balancer (ALB)** público, com roteamento por caminho:
  - `/` e `/products*` -> microsserviço de catálogo.
  - `/orders*` -> microsserviço de pedidos.
- **Amazon ECS com AWS Fargate** para executar os dois microsserviços em containers Docker.
- **Amazon ECR** para armazenar as imagens Docker.
- **Amazon DynamoDB** para persistir produtos e pedidos.
- **Amazon SQS** para receber eventos de novos pedidos.
- **AWS Lambda** acionada pela fila SQS para processar os eventos.
- **Amazon CloudWatch Logs** para registrar a execução da Lambda.

O ALB é público. As tarefas ECS recebem IP público para acessar ECR, SQS, DynamoDB e CloudWatch sem NAT Gateway. O Security Group das tarefas aceita tráfego HTTP somente do Security Group do ALB. Para produção, recomenda-se mover as tarefas para sub-redes privadas e utilizar NAT Gateway ou VPC Endpoints.

## 2. Pré-requisitos

Instale e configure:

1. Uma conta AWS com permissões para criar VPC, EC2, ECS, ECR, IAM, ALB, Lambda, SQS, DynamoDB e CloudWatch.
2. AWS CLI v2 (`aws --version`).
3. Terraform >= 1.5 (`terraform version`).
4. Docker (`docker --version`).
5. Git.

Configure suas credenciais AWS no terminal:

```bash
aws configure
aws sts get-caller-identity
```

Nunca coloque access keys, senhas ou tokens no repositório.

## 3. Estrutura do repositório

```text
ecommerce-cloud-aws/
├── app/
│   ├── catalog/
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   └── orders/
│       ├── app.py
│       ├── requirements.txt
│       └── Dockerfile
├── lambda/
│   └── handler.py
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── deploy.sh
├── deploy.ps1
└── .gitignore
```

## 4. Como configurar

Entre na pasta `terraform` e, se desejar, altere `terraform/variables.tf` ou defina `AWS_REGION` e `PROJECT_NAME` antes de executar o script. A região padrão é `us-east-1`.

O nome dos repositórios ECR e demais recursos recebe um prefixo configurável (`project_name`).

## 5. Como executar o deploy

### Windows (PowerShell)

Na raiz do projeto, execute:

```powershell
.\deploy.ps1
```

Se a política de execução bloquear o script, abra o PowerShell e execute:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\deploy.ps1
```

### Linux / macOS

```bash
chmod +x deploy.sh
./deploy.sh
```

O script realiza duas etapas importantes:

1. Cria inicialmente os repositórios ECR no Terraform.
2. Constrói e envia as imagens Docker para o ECR.
3. Aplica o restante da infraestrutura, incluindo ECS, ALB, SQS, Lambda e DynamoDB.

O primeiro `terraform apply` completo pode levar alguns minutos. Aguarde o serviço ECS ficar estável.

## 6. Testar a aplicação

Ao final do deploy, o Terraform informa `alb_url`.

Exemplos (substitua `ALB_URL` pelo endereço exibido):

```bash
curl http://ALB_URL/
curl http://ALB_URL/health
curl http://ALB_URL/products
curl -X POST http://ALB_URL/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id":"produto-001","quantity":2,"customer":"Cliente de teste"}'
```

O endpoint de pedidos grava o pedido no DynamoDB e envia uma mensagem para o SQS. A Lambda consome a mensagem e registra o processamento no CloudWatch.

Para consultar os pedidos, use o endpoint:

```bash
curl http://ALB_URL/orders
```

## 7. Como comprovar o funcionamento (exigência da atividade)

Inclua no README ou em uma pasta `docs/` capturas de tela reais da sua conta AWS:

1. **Aplicação no ALB:** abra a URL `alb_url` no navegador e capture a página inicial.
2. **Lambda / CloudWatch:** crie um pedido com `POST /orders`, abra CloudWatch > Log groups > `/aws/lambda/ecommerce-cloud-processor` (o nome pode variar conforme o prefixo) e capture um log de processamento.
3. **Terraform:** capture o terminal ao final de `terraform apply`, mostrando `Apply complete!` e os outputs.

Crie a pasta `docs/screenshots/` e salve as imagens nela. Não utilize imagens simuladas: as evidências devem ser capturadas após o deploy real.

## 8. Comandos úteis

```bash
cd terraform
terraform fmt -recursive
terraform validate
terraform plan
terraform output
```

Para destruir os recursos e evitar cobranças depois dos testes:

```bash
cd terraform
terraform destroy
```

Confirme a destruição quando solicitado. O ALB, ECS e outros recursos podem gerar custos enquanto estiverem ativos.

## 9. Observações de segurança e custos

- Não versionar arquivos `*.tfstate`, credenciais ou arquivos `.env`.
- O exemplo usa HTTP no ALB para simplificar a atividade. Em produção, configure HTTPS com certificado ACM e redirecionamento HTTP -> HTTPS.
- O uso de IP público nas tarefas é uma simplificação didática. Em produção, prefira sub-redes privadas e VPC Endpoints/NAT.
- DynamoDB usa capacidade sob demanda.
- Revise os recursos ativos e execute `terraform destroy` após a avaliação, se não precisar manter o ambiente.
