# Empaquetar Lambdas
data "archive_file" "notify_alert" {
  type        = "zip"
  source_dir  = "../lambdas/notifyAlert"
  output_path = "../build/notifyAlert.zip"
}
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
resource "aws_lambda_function" "notify_alert" {
  filename         = data.archive_file.notify_alert.output_path
  source_code_hash = data.archive_file.notify_alert.output_base64sha256
  function_name    = "notifyAlert"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  code_signing_config_arn        = aws_lambda_code_signing_config.notify_alert.arn
  reserved_concurrent_executions = 1000

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.attendance_alerts.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
}
resource "aws_lambda_function" "register_student" {
  filename         = data.archive_file.register_student.output_path
  source_code_hash = data.archive_file.register_student.output_base64sha256
  function_name    = "registerStudent"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  code_signing_config_arn        = aws_lambda_code_signing_config.register_student.arn
  reserved_concurrent_executions = 1000
environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.attendance_alerts.arn
    }
  }
  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.tardanza_queue.arn
  }

  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
}

resource "aws_lambda_function" "list_students" {
  filename         = data.archive_file.list_students.output_path
  source_code_hash = data.archive_file.list_students.output_base64sha256
  function_name    = "listStudents"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  code_signing_config_arn        = aws_lambda_code_signing_config.list_students.arn
  reserved_concurrent_executions = 1000

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.tardanza_queue.arn
  }

  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
}

resource "aws_lambda_function" "attendance" {
  filename         = data.archive_file.attendance.output_path
  source_code_hash = data.archive_file.attendance.output_base64sha256
  function_name    = "attendance"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  code_signing_config_arn        = aws_lambda_code_signing_config.attendance.arn
  reserved_concurrent_executions = 1000

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.tardanza_queue.arn
  }

  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
}

resource "aws_lambda_function" "manual_attendance" {
  filename         = data.archive_file.manual_attendance.output_path
  source_code_hash = data.archive_file.manual_attendance.output_base64sha256
  function_name    = "manualAttendance"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  code_signing_config_arn        = aws_lambda_code_signing_config.manual_attendance.arn
  reserved_concurrent_executions = 1000

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.tardanza_queue.arn
  }

  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
}

resource "aws_lambda_function" "attendance_history" {
  filename         = data.archive_file.attendance_history.output_path
  source_code_hash = data.archive_file.attendance_history.output_base64sha256
  function_name    = "attendanceHistory"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda_role.arn
  code_signing_config_arn        = aws_lambda_code_signing_config.attendance_history.arn
  reserved_concurrent_executions = 1000

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.tardanza_queue.arn
  }

  vpc_config {
    subnet_ids         = []
    security_group_ids = []
  }
}
resource "aws_lambda_code_signing_config" "notify_alert" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.notify_alert.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}
resource "aws_lambda_code_signing_config" "register_student" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.register_student.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_lambda_code_signing_config" "list_students" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.list_students.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_lambda_code_signing_config" "attendance" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.attendance.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_lambda_code_signing_config" "manual_attendance" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.manual_attendance.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_lambda_code_signing_config" "attendance_history" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.attendance_history.version_arn]
  }
  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}