resource "aws_api_gateway_deployment" "attendance" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  depends_on = [
    aws_api_gateway_integration.register_student,
    aws_api_gateway_integration.list_students,
    aws_api_gateway_integration.attendance,
    aws_api_gateway_integration.manual_attendance,
    aws_api_gateway_integration.attendance_history,
    aws_api_gateway_integration.delete_student,
    aws_api_gateway_integration_response.cors,
    aws_api_gateway_gateway_response.default_4xx,
    aws_api_gateway_gateway_response.default_5xx
  ]

  triggers = {
    redeployment = sha1(jsonencode(concat([
      aws_api_gateway_model.student_request.id,
      aws_api_gateway_model.attendance_rfid_request.id,
      aws_api_gateway_model.attendance_manual_request.id,
      aws_api_gateway_integration.register_student.id,
      aws_api_gateway_integration.list_students.id,
      aws_api_gateway_integration.attendance.id,
      aws_api_gateway_integration.manual_attendance.id,
      aws_api_gateway_integration.attendance_history.id,
      aws_api_gateway_integration.delete_student.id
    ], [for response in aws_api_gateway_integration_response.cors : response.id])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  #checkov:skip=CKV_AWS_120:Cache deshabilitado para evitar cachear POST/DELETE de asistencia y registros.
  #checkov:skip=CKV2_AWS_4:Logging configurado en aws_api_gateway_method_settings
  #checkov:skip=CKV2_AWS_29:WAF asociado via aws_wafv2_web_acl_association
  #checkov:skip=CKV2_AWS_77:WAF con regla AWSManagedRulesKnownBadInputsRuleSet incluida
  stage_name           = "prod"
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  deployment_id        = aws_api_gateway_deployment.attendance.id
  xray_tracing_enabled = true
  depends_on           = [aws_api_gateway_account.cloudwatch]

  client_certificate_id = aws_api_gateway_client_certificate.cert.id

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

resource "aws_api_gateway_client_certificate" "cert" {
  description = "Certificado de cliente para API Gateway"
}

resource "aws_api_gateway_method_settings" "all" {
  #checkov:skip=CKV_AWS_225:Cache deshabilitado para no cachear escrituras POST/DELETE de asistencia.
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = false
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/attendance-api"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.dynamo_key.arn
}
