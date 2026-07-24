resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "attendance-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs" {
  role       = aws_iam_role.api_gateway_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "cloudwatch" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}

locals {
  lambda_function_names = {
    notify_alert       = "notifyAlert"
    register_student   = "registerStudent"
    list_students      = "listStudents"
    attendance         = "attendance"
    manual_attendance  = "manualAttendance"
    attendance_history = "attendanceHistory"
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each          = local.lambda_function_names
  name              = "/aws/lambda/${each.value}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.dynamo_key.arn
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-attendance-api"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.dynamo_key.arn
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "attendance-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Errores 5xx en API Gateway durante 5 minutos."
  alarm_actions       = [aws_sns_topic.attendance_alerts.arn]

  dimensions = {
    ApiName = aws_api_gateway_rest_api.attendance_api.name
    Stage   = aws_api_gateway_stage.prod.stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "tardanza_dlq_messages" {
  alarm_name          = "attendance-tardanza-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Mensajes acumulados en la DLQ de tardanzas."
  alarm_actions       = [aws_sns_topic.attendance_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.tardanza_dlq.name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_dlq_messages" {
  alarm_name          = "attendance-lambda-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Mensajes acumulados en la DLQ tecnica de Lambdas."
  alarm_actions       = [aws_sns_topic.attendance_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.lambda_dlq.name
  }
}
