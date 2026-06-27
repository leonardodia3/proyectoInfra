# Attendance rest api
resource "aws_api_gateway_rest_api" "attendance_api" {
  name        = "attendance-api"
  description = "API Control de Asistencia"
  lifecycle {
    create_before_destroy = true
  }
}

# Recurso /students
resource "aws_api_gateway_resource" "students" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_rest_api.attendance_api.root_resource_id
  path_part   = "students"
}

# POST /students
resource "aws_api_gateway_method" "post_students" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  resource_id   = aws_api_gateway_resource.students.id
  http_method   = "POST"
  authorization = "NONE" # nosonar
  #authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "register_student" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.students.id
  http_method             = aws_api_gateway_method.post_students.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_student.invoke_arn
}

# GET /students
resource "aws_api_gateway_method" "get_students" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  resource_id   = aws_api_gateway_resource.students.id
  http_method   = "GET"
  authorization = "NONE" # nosonar
  #authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "list_students" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.students.id
  http_method             = aws_api_gateway_method.get_students.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_students.invoke_arn
}

# Permisos
resource "aws_lambda_permission" "register_student" {
  statement_id  = "AllowApiGatewayInvokeRegister"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_student.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "attendance" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  depends_on = [
    aws_api_gateway_integration.register_student,
    aws_api_gateway_integration.list_students
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  deployment_id = aws_api_gateway_deployment.attendance.id
  xray_tracing_enabled = true

  # CKV_AWS_76 - Access Logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
  }
}

# CKV2_AWS_4 - Logging level para REST API
# CKV_AWS_120 / CKV_AWS_225 - Caching habilitado
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    caching_enabled    = true
    cache_data_encrypted = true
  }
}

# CKV_AWS_158 - CloudWatch Log Group cifrado con KMS
# CKV_AWS_338 - Retención de al menos 1 año (365 días)
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/attendance-api"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.dynamo_key.arn
}
