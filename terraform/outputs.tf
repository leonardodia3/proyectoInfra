output "api_url" {
  description = "URL base de tu API desplegada"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito"
  value       = aws_cognito_user_pool.attendance_pool.id
}

output "cognito_client_id" {
  description = "ID del cliente de la app de Cognito"
  value       = aws_cognito_user_pool_client.attendance_client.id
}

output "esp32_api_key_id" {
  description = "ID de la API Key del ESP32 (el valor real se obtiene con un comando aparte)"
  value       = aws_api_gateway_api_key.esp32_key.id
}