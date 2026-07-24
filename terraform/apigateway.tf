resource "aws_api_gateway_rest_api" "attendance_api" {
  name        = "attendance-api"
  description = "API Control de Asistencia"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  name          = "cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.attendance_pool.arn]
}
