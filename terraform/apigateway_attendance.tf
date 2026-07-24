resource "aws_api_gateway_resource" "attendance" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_rest_api.attendance_api.root_resource_id
  path_part   = "attendance"
}

resource "aws_api_gateway_method" "post_attendance" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.attendance.id
  http_method          = "POST"
  authorization        = "NONE"
  api_key_required     = true
  request_validator_id = aws_api_gateway_request_validator.validator.id

  request_models = {
    "application/json" = aws_api_gateway_model.attendance_rfid_request.name
  }
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
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/POST/attendance"
}

resource "aws_api_gateway_resource" "attendance_manual" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_resource.attendance.id
  path_part   = "manual"
}

resource "aws_api_gateway_method" "post_attendance_manual" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.attendance_manual.id
  http_method          = "POST"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id

  request_models = {
    "application/json" = aws_api_gateway_model.attendance_manual_request.name
  }
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
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/POST/attendance/manual"
}

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

resource "aws_api_gateway_method" "get_attendance_history" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.attendance_history_dni.id
  http_method          = "GET"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id

  request_parameters = {
    "method.request.path.dni" = true
  }
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
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/GET/attendance/history/*"
}

resource "aws_api_gateway_api_key" "esp32_key" {
  name = "esp32-rfid-key"
}

resource "aws_api_gateway_usage_plan" "esp32_plan" {
  name = "esp32-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.attendance_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  quota_settings {
    limit  = 100000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 200
    rate_limit  = 100
  }
}

resource "aws_api_gateway_usage_plan_key" "esp32_key_link" {
  key_id        = aws_api_gateway_api_key.esp32_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.esp32_plan.id
}
