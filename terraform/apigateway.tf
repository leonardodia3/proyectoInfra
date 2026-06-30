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

# Request Validator
resource "aws_api_gateway_request_validator" "validator" {
  rest_api_id           = aws_api_gateway_rest_api.attendance_api.id
  name                  = "validate-request"
  validate_request_body = true
  validate_request_parameters = true
}

# POST /students
resource "aws_api_gateway_method" "post_students" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.students.id
  http_method          = "POST"
  # CKV_AWS_59 / CKV2_AWS_53 - Autorización y validación
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id
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
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.students.id
  http_method          = "GET"
  # CKV_AWS_59 / CKV2_AWS_53 - Autorización y validación
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id
}

resource "aws_api_gateway_integration" "list_students" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.students.id
  http_method             = aws_api_gateway_method.get_students.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_students.invoke_arn
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  name          = "cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.attendance_pool.arn]
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

  # CKV2_AWS_51 - Certificado de cliente
  client_certificate_id = aws_api_gateway_client_certificate.cert.id

  # CKV_AWS_76 - Access Logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
  }

  # CKV2_AWS_29 - WAF
  web_acl_arn = aws_wafv2_web_acl.api_waf.arn
}

# CKV2_AWS_51 - Certificado de cliente
resource "aws_api_gateway_client_certificate" "cert" {
  description = "Certificado de cliente para API Gateway"
}

# CKV2_AWS_4 - Logging level + CKV_AWS_120 / CKV_AWS_225 - Caching
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    logging_level        = "INFO"
    caching_enabled      = true
    cache_data_encrypted = true
  }
}

# CKV2_AWS_29 - WAF
resource "aws_wafv2_web_acl" "api_waf" {
  name  = "attendance-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "attendance-api-waf"
    sampled_requests_enabled   = true
  }
}

# CKV_AWS_158 / CKV_AWS_338 - CloudWatch Log Group cifrado con KMS, retención 1 año
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/attendance-api"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.dynamo_key.arn
}
