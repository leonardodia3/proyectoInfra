resource "aws_api_gateway_resource" "students" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_rest_api.attendance_api.root_resource_id
  path_part   = "students"
}

resource "aws_api_gateway_method" "post_students" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.students.id
  http_method          = "POST"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id

  request_models = {
    "application/json" = aws_api_gateway_model.student_request.name
  }
}

resource "aws_api_gateway_integration" "register_student" {
  rest_api_id             = aws_api_gateway_rest_api.attendance_api.id
  resource_id             = aws_api_gateway_resource.students.id
  http_method             = aws_api_gateway_method.post_students.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_student.invoke_arn
}

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

resource "aws_lambda_permission" "register_student" {
  statement_id  = "AllowApiGatewayInvokeRegister"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_student.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/POST/students"
}

resource "aws_lambda_permission" "list_students" {
  statement_id  = "AllowApiGatewayInvokeListStudents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_students.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/GET/students"
}

resource "aws_api_gateway_resource" "students_dni" {
  rest_api_id = aws_api_gateway_rest_api.attendance_api.id
  parent_id   = aws_api_gateway_resource.students.id
  path_part   = "{dni}"
}

resource "aws_api_gateway_method" "delete_student" {
  rest_api_id          = aws_api_gateway_rest_api.attendance_api.id
  resource_id          = aws_api_gateway_resource.students_dni.id
  http_method          = "DELETE"
  authorization        = "COGNITO_USER_POOLS"
  authorizer_id        = aws_api_gateway_authorizer.cognito.id
  request_validator_id = aws_api_gateway_request_validator.validator.id

  request_parameters = {
    "method.request.path.dni" = true
  }
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
  source_arn    = "${aws_api_gateway_rest_api.attendance_api.execution_arn}/*/DELETE/students/*"
}
