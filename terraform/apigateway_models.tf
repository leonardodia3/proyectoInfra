resource "aws_api_gateway_request_validator" "validator" {
  rest_api_id                 = aws_api_gateway_rest_api.attendance_api.id
  name                        = "validate-request"
  validate_request_body       = true
  validate_request_parameters = true
}

resource "aws_api_gateway_model" "student_request" {
  rest_api_id  = aws_api_gateway_rest_api.attendance_api.id
  name         = "StudentRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    required  = ["dni", "name", "email", "classroom", "rfid"]
    properties = {
      dni       = { type = "string", pattern = "^[0-9]{8}$" }
      name      = { type = "string", minLength = 1 }
      email     = { type = "string", minLength = 3 }
      classroom = { type = "string", minLength = 1 }
      nombre    = { type = "string", minLength = 1 }
      correo    = { type = "string", minLength = 3 }
      rfid      = { type = "string", minLength = 1 }
      salon     = { type = "string", minLength = 1 }
      seccion   = { type = "string", minLength = 1 }
    }
  })
}

resource "aws_api_gateway_model" "attendance_rfid_request" {
  rest_api_id  = aws_api_gateway_rest_api.attendance_api.id
  name         = "AttendanceRfidRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    required  = ["rfid"]
    properties = {
      rfid      = { type = "string", minLength = 1 }
      timestamp = { type = "string" }
    }
  })
}

resource "aws_api_gateway_model" "attendance_manual_request" {
  rest_api_id  = aws_api_gateway_rest_api.attendance_api.id
  name         = "AttendanceManualRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    required  = ["dni"]
    properties = {
      dni       = { type = "string", pattern = "^[0-9]{8}$" }
      timestamp = { type = "string" }
    }
  })
}
