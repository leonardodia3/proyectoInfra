# Empaquetar Lambdas
data "archive_file" "register_student" {
  type        = "zip"
  source_dir  = "../lambdas/registerStudent"
  output_path = "../build/registerStudent.zip"
}

data "archive_file" "list_students" {
  type        = "zip"
  source_dir  = "../lambdas/listStudents"
  output_path = "../build/listStudents.zip"
}

data "archive_file" "attendance" {
  type        = "zip"
  source_dir  = "../lambdas/attendance"
  output_path = "../build/attendance.zip"
}

data "archive_file" "manual_attendance" {
  type        = "zip"
  source_dir  = "../lambdas/manualAttendance"
  output_path = "../build/manualAttendance.zip"
}

data "archive_file" "attendance_history" {
  type        = "zip"
  source_dir  = "../lambdas/attendanceHistory"
  output_path = "../build/attendanceHistory.zip"
}

# Lambdas
resource "aws_lambda_function" "register_student" {
  filename         = data.archive_file.register_student.output_path
  source_code_hash = data.archive_file.register_student.output_base64sha256

  function_name = "registerStudent"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "list_students" {
  filename         = data.archive_file.list_students.output_path
  source_code_hash = data.archive_file.list_students.output_base64sha256

  function_name = "listStudents"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "attendance" {
  filename         = data.archive_file.attendance.output_path
  source_code_hash = data.archive_file.attendance.output_base64sha256
  function_name    = "attendance"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "manual_attendance" {
  filename         = data.archive_file.manual_attendance.output_path
  source_code_hash = data.archive_file.manual_attendance.output_base64sha256
  function_name    = "manualAttendance"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_function" "attendance_history" {
  filename         = data.archive_file.attendance_history.output_path
  source_code_hash = data.archive_file.attendance_history.output_base64sha256
  function_name = "attendanceHistory"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_role.arn
}
