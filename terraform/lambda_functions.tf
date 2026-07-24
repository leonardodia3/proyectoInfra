resource "aws_lambda_function" "notify_alert" {
  #checkov:skip=CKV_AWS_117:No requiere VPC; solo consume SQS y publica SNS gestionados por AWS.
  filename                       = data.archive_file.notify_alert.output_path
  source_code_hash               = data.archive_file.notify_alert.output_base64sha256
  function_name                  = "notifyAlert"
  handler                        = "index.handler"
  runtime                        = "nodejs20.x"
  role                           = aws_iam_role.lambda["notify_alert"].arn
  code_signing_config_arn        = aws_lambda_code_signing_config.notify_alert.arn
  kms_key_arn                    = aws_kms_key.dynamo_key.arn
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  timeout                        = 10

  environment {
    variables = {
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
      SNS_TOPIC_ARN       = aws_sns_topic.attendance_alerts.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_lambda_function" "register_student" {
  #checkov:skip=CKV_AWS_117:No requiere VPC; usa DynamoDB y SNS gestionados por AWS.
  filename                       = data.archive_file.register_student.output_path
  source_code_hash               = data.archive_file.register_student.output_base64sha256
  function_name                  = "registerStudent"
  handler                        = "index.handler"
  runtime                        = "nodejs20.x"
  role                           = aws_iam_role.lambda["register_student"].arn
  code_signing_config_arn        = aws_lambda_code_signing_config.register_student.arn
  kms_key_arn                    = aws_kms_key.dynamo_key.arn
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  timeout                        = 10

  environment {
    variables = {
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
      TABLE_NAME          = aws_dynamodb_table.attendance.name
      RFID_INDEX_NAME     = local.rfid_index_name
      SNS_TOPIC_ARN       = aws_sns_topic.attendance_alerts.arn
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_lambda_function" "list_students" {
  #checkov:skip=CKV_AWS_117:No requiere VPC; consulta DynamoDB gestionado por AWS.
  filename                       = data.archive_file.list_students.output_path
  source_code_hash               = data.archive_file.list_students.output_base64sha256
  function_name                  = "listStudents"
  handler                        = "index.handler"
  runtime                        = "nodejs20.x"
  role                           = aws_iam_role.lambda["list_students"].arn
  code_signing_config_arn        = aws_lambda_code_signing_config.list_students.arn
  kms_key_arn                    = aws_kms_key.dynamo_key.arn
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  timeout                        = 10

  environment {
    variables = {
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
      TABLE_NAME          = aws_dynamodb_table.attendance.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_lambda_function" "attendance" {
  #checkov:skip=CKV_AWS_117:No requiere VPC; escribe DynamoDB y envia SQS gestionados por AWS.
  filename                       = data.archive_file.attendance.output_path
  source_code_hash               = data.archive_file.attendance.output_base64sha256
  function_name                  = "attendance"
  handler                        = "index.handler"
  runtime                        = "nodejs20.x"
  role                           = aws_iam_role.lambda["attendance"].arn
  code_signing_config_arn        = aws_lambda_code_signing_config.attendance.arn
  kms_key_arn                    = aws_kms_key.dynamo_key.arn
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  timeout                        = 10

  environment {
    variables = {
      CORS_ALLOWED_ORIGIN  = var.cors_allowed_origin
      ATTENDANCE_DEADLINE  = var.attendance_deadline
      ATTENDANCE_TIME_ZONE = var.attendance_time_zone
      RFID_INDEX_NAME      = local.rfid_index_name
      TABLE_NAME           = aws_dynamodb_table.attendance.name
      TARDANZA_QUEUE_URL   = aws_sqs_queue.tardanza_queue.url
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_lambda_function" "manual_attendance" {
  #checkov:skip=CKV_AWS_117:No requiere VPC; escribe DynamoDB gestionado por AWS.
  filename                       = data.archive_file.manual_attendance.output_path
  source_code_hash               = data.archive_file.manual_attendance.output_base64sha256
  function_name                  = "manualAttendance"
  handler                        = "index.handler"
  runtime                        = "nodejs20.x"
  role                           = aws_iam_role.lambda["manual_attendance"].arn
  code_signing_config_arn        = aws_lambda_code_signing_config.manual_attendance.arn
  kms_key_arn                    = aws_kms_key.dynamo_key.arn
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  timeout                        = 10

  environment {
    variables = {
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
      TABLE_NAME          = aws_dynamodb_table.attendance.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_lambda_function" "attendance_history" {
  #checkov:skip=CKV_AWS_117:No requiere VPC; consulta DynamoDB gestionado por AWS.
  filename                       = data.archive_file.attendance_history.output_path
  source_code_hash               = data.archive_file.attendance_history.output_base64sha256
  function_name                  = "attendanceHistory"
  handler                        = "index.handler"
  runtime                        = "nodejs20.x"
  role                           = aws_iam_role.lambda["attendance_history"].arn
  code_signing_config_arn        = aws_lambda_code_signing_config.attendance_history.arn
  kms_key_arn                    = aws_kms_key.dynamo_key.arn
  reserved_concurrent_executions = var.lambda_reserved_concurrency
  timeout                        = 10

  environment {
    variables = {
      CORS_ALLOWED_ORIGIN = var.cors_allowed_origin
      TABLE_NAME          = aws_dynamodb_table.attendance.name
    }
  }

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}
