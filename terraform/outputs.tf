output "alb_url" {
  description = "URL pública da aplicação."
  value       = "http://${aws_lb.main.dns_name}"
}
output "catalog_ecr_url" {
  value = aws_ecr_repository.catalog.repository_url
}
output "orders_ecr_url" {
  value = aws_ecr_repository.orders.repository_url
}
output "sqs_queue_url" {
  value = aws_sqs_queue.orders.url
}
output "lambda_function_name" {
  value = aws_lambda_function.processor.function_name
}
