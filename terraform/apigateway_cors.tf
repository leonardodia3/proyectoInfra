locals {
  cors_resources = {
    attendance             = aws_api_gateway_resource.attendance.id
    attendance_history_dni = aws_api_gateway_resource.attendance_history_dni.id
    attendance_manual      = aws_api_gateway_resource.attendance_manual.id
    students               = aws_api_gateway_resource.students.id
    students_dni           = aws_api_gateway_resource.students_dni.id
  }

  cors_allowed_headers = "Content-Type,Authorization,X-Api-Key"
  cors_allowed_methods = "GET,POST,DELETE,OPTIONS"
}

resource "aws_api_gateway_method" "cors" {
  #checkov:skip=CKV2_AWS_53:OPTIONS CORS no recibe datos de negocio; la validacion esta en los metodos reales.
  for_each      = local.cors_resources
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.cors[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "cors" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  for_each    = local.cors_resources
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  resource_id = each.value
  http_method = aws_api_gateway_method.cors[each.key].http_method
  status_code = aws_api_gateway_method_response.cors[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'${local.cors_allowed_headers}'"
    "method.response.header.Access-Control-Allow-Methods" = "'${local.cors_allowed_methods}'"
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
  }

  depends_on = [aws_api_gateway_integration.cors]
}

resource "aws_api_gateway_gateway_response" "default_4xx" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  response_type = "DEFAULT_4XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'${local.cors_allowed_headers}'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'${local.cors_allowed_methods}'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
  }
}

resource "aws_api_gateway_gateway_response" "default_5xx" {
  rest_api_id   = aws_api_gateway_rest_api.attendance_api.id
  response_type = "DEFAULT_5XX"

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'${local.cors_allowed_headers}'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'${local.cors_allowed_methods}'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'${var.cors_allowed_origin}'"
  }
}
