resource "aws_sqs_queue" "tardanza_dlq" {
  name                      = "tardanza-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.dynamo_key.key_id
}

resource "aws_sqs_queue" "tardanza_queue" {
  name                       = "tardanza-queue"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 60
  kms_master_key_id          = aws_kms_key.dynamo_key.key_id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.tardanza_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue" "lambda_dlq" {
  name                      = "lambda-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = aws_kms_key.dynamo_key.key_id
}

resource "aws_iam_role_policy" "attendance_send_tardanza" {
  name = "lambda-sqs-attendance-send-policy"
  role = aws_iam_role.lambda["attendance"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.tardanza_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "notify_alert_consume_tardanza" {
  name = "lambda-sqs-notify-alert-consume-policy"
  role = aws_iam_role.lambda["notify_alert"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.tardanza_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dlq_send" {
  for_each = aws_iam_role.lambda
  name     = "lambda-dlq-send-${each.key}-policy"
  role     = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:SendMessage"]
        Resource = aws_sqs_queue.lambda_dlq.arn
      }
    ]
  })
}

resource "aws_lambda_event_source_mapping" "sqs_to_notificador" {
  event_source_arn = aws_sqs_queue.tardanza_queue.arn
  function_name    = aws_lambda_function.notify_alert.arn
  batch_size       = 1
}
