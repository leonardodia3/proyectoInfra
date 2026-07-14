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
  rest_api_id                 = aws_api_gateway_rest_api.attendance_api.id
  name                        = "validate-request"
  validate_request_body       = true
  validate_request_parameters = true
}

# POST /students
resource "aws_api_gateway_method" "post_students" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.students.id
  http_method          = "POST"
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

# Permisos /students
resource "aws_lambda_permission" "register_student" {
  statement_id  = "AllowApiGatewayInvokeRegister"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_student.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/*"
}

# ===== Recurso /attendance =====
resource "aws_api_gateway_resource" "attendance" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_rest_api.attendance_api.root_resource_id
  path_part   = "attendance"
}

# sonarqube:skip S6333 - Endpoint público intencional para el ESP32,
# protegido con API Key en vez de Cognito (un dispositivo no puede autenticarse como usuario)
resource "aws_api_gateway_method" "post_attendance" {
  rest_api_id      = aws_api_gateway_rest_api.attendance_api.id
  resource_id      = aws_api_gateway_resource.attendance.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "attendance" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.attendance.id
  http_method             = aws_api_gateway_method.post_attendance.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.attendance.invoke_arn
}

resource "aws_lambda_permission" "attendance" {
  statement_id  = "AllowApiGatewayInvokeAttendance"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.attendance.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/*"
}

# ===== Recurso /attendance/manual =====
resource "aws_api_gateway_resource" "attendance_manual" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_resource.attendance.id
  path_part   = "manual"
}

# POST /attendance/manual (vigilante, con Cognito)
resource "aws_api_gateway_method" "post_attendance_manual" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.attendance_manual.id
  http_method          = "POST"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id
}

resource "aws_api_gateway_integration" "manual_attendance" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.attendance_manual.id
  http_method             = aws_api_gateway_method.post_attendance_manual.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.manual_attendance.invoke_arn
}

resource "aws_lambda_permission" "manual_attendance" {
  statement_id  = "AllowApiGatewayInvokeManualAttendance"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.manual_attendance.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/*"
}

# ===== Recurso /attendance/history/{dni} =====
resource "aws_api_gateway_resource" "attendance_history" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_resource.attendance.id
  path_part   = "history"
}

resource "aws_api_gateway_resource" "attendance_history_dni" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_resource.attendance_history.id
  path_part   = "{dni}"
}

# GET /attendance/history/{dni} (con Cognito)
resource "aws_api_gateway_method" "get_attendance_history" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  resource_id   = aws_api_gateway_resource.attendance_history_dni.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "attendance_history" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.attendance_history_dni.id
  http_method             = aws_api_gateway_method.get_attendance_history.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.attendance_history.invoke_arn
}

resource "aws_lambda_permission" "attendance_history" {
  statement_id  = "AllowApiGatewayInvokeAttendanceHistory"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.attendance_history.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/*"
}

# ===== API Key para el ESP32 =====
resource "aws_api_gateway_api_key" "esp32_key" {
  name = "esp32-rfid-key"
}

resource "aws_api_gateway_usage_plan" "esp32_plan" {
  name = "esp32-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.attendance_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "esp32_key_link" {
  key_id        = aws_api_gateway_api_key.esp32_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.esp32_plan.id
}

# Recurso /students/{dni}
resource "aws_api_gateway_resource" "students_dni" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_resource.students.id
  path_part   = "{dni}"
}

# DELETE /students/{dni} (solo Director, con Cognito)
resource "aws_api_gateway_method" "delete_student" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  resource_id   = aws_api_gateway_resource.students_dni.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "delete_student" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.students_dni.id
  http_method             = aws_api_gateway_method.delete_student.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_student.invoke_arn
}

resource "aws_lambda_permission" "delete_student" {
  statement_id  = "AllowApiGatewayInvokeDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_student.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/*"
}

# ===== Deployment (UN SOLO bloque, con todas las integraciones) =====
resource "aws_api_gateway_deployment" "attendance" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  depends_on = [
    aws_api_gateway_integration.register_student,
    aws_api_gateway_integration.list_students,
    aws_api_gateway_integration.attendance,
    aws_api_gateway_integration.manual_attendance,
    aws_api_gateway_integration.attendance_history,
    aws_api_gateway_integration.delete_student
  ]
  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "prod" {
  #checkov:skip=CKV_AWS_120:Caching configurado en aws_api_gateway_method_settings
  #checkov:skip=CKV2_AWS_4:Logging configurado en aws_api_gateway_method_settings
  #checkov:skip=CKV2_AWS_29:WAF asociado via aws_wafv2_web_acl_association
  #checkov:skip=CKV2_AWS_77:WAF con regla AWSManagedRulesKnownBadInputsRuleSet incluida
  stage_name           = "prod"
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  deployment_id        = aws_api_gateway_deployment.attendance.id
  xray_tracing_enabled = true

  # CKV2_AWS_51 - Certificado de cliente
  client_certificate_id = aws_api_gateway_client_certificate.cert.id

  # CKV_AWS_76 - Access Logging
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# CKV2_AWS_51 - Certificado de cliente
resource "aws_api_gateway_client_certificate" "cert" {
  description = "Certificado de cliente para API Gateway"
}

# CKV2_AWS_4 / CKV_AWS_120 / CKV_AWS_225 - Logging level y Caching
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

# WAF con reglas
resource "aws_wafv2_web_acl" "api_waf" {
  name  = "attendance-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "attendance-api-waf"
    sampled_requests_enabled   = true
  }
}

# WAF Logging
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.api_waf.arn
}

# WAF Association con API Gateway
resource "aws_wafv2_web_acl_association" "api_waf_association" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/attendance-api"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.dynamo_key.arn
}