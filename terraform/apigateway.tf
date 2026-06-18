# Attendance rest api
resource "aws_api_gateway_rest_api" "attendance_api" {
  name = "attendance-api"
  description = "API Control de Asistencia"
}
# Recurso /students
resource "aws_api_gateway_resource" "students" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id = aws_api_gateway_rest_api.attendance_api.root_resource_id
  path_part = "students"
}

# POST /
# Api completa POST /students
resource "aws_api_gateway_method" "post_students" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  resource_id = aws_api_gateway_resource.students.id
  http_method = "POST"
  authorization = "NONE" #"COGNITO_USER_POOLS"
  #authorizer_id = aws_api_gateway_authorizer.cognito.id
}
resource "aws_api_gateway_integration" "register_student" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  resource_id = aws_api_gateway_resource.students.id
  http_method = aws_api_gateway_method.post_students.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.register_student.invoke_arn
}

# GET /
# Api completa GET /students
resource "aws_api_gateway_method" "get_students" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  resource_id = aws_api_gateway_resource.students.id
  http_method = "GET"
  authorization = "NONE" #"COGNITO_USER_POOLS"
  #authorizer_id = aws_api_gateway_authorizer.cognito.id
}
resource "aws_api_gateway_integration" "list_students" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  resource_id = aws_api_gateway_resource.students.id
  http_method = aws_api_gateway_method.get_students.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.list_students.invoke_arn
}

# Permisos
resource "aws_lambda_permission" "register_student" {
  statement_id = "AllowApiGatewayInvokeRegister"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_student.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "attendance" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  depends_on = [
    aws_api_gateway_integration.register_student,
    aws_api_gateway_integration.list_students
  ]
}

#Stage
resource "aws_api_gateway_stage" "prod" {
  stage_name = "prod"
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  deployment_id = aws_api_gateway_deployment.attendance.id
}