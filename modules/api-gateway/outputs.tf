output "api_endpoint" {
  description = "Base endpoint URL for the API Gateway stage."
  value       = aws_apigatewayv2_stage.shortener.invoke_url
}

output "api_id" {
  description = "ID of the API Gateway HTTP API."
  value       = aws_apigatewayv2_api.shortener.id
}
