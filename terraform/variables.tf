variable "aws_region" {
  description = "Região AWS onde os recursos serão criados."
  type        = string
  default     = "us-east-1"
}
variable "project_name" {
  description = "Prefixo curto usado nos nomes dos recursos."
  type        = string
  default     = "ecommerce-cloud"
}
variable "container_port" {
  description = "Porta HTTP dos microsserviços."
  type        = number
  default     = 5000
}
variable "desired_count" {
  description = "Quantidade de tarefas por microsserviço."
  type        = number
  default     = 1
}
