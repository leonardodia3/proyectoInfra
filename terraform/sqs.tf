resource "aws_sqs_queue" "tardanza_queue" {
  name                      = "tardanza-queue"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
}

# Permiso para que Lambda encole y consuma mensajes
resource "aws_iam_role_policy" "lambda_sqs_policy" {
  name = "lambda-sqs-attendance-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.tardanza_queue.arn
      }
    ]
  })
}

# Trigger: SQS activa Lambda notificador de alertas
resource "aws_lambda_event_source_mapping" "sqs_to_notificador" {
  event_source_arn = aws_sqs_queue.tardanza_queue.arn
  function_name    = aws_lambda_function.attendance.arn
  batch_size       = 1
}