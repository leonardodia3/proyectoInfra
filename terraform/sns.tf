resource "aws_sns_topic" "attendance_alerts" {
  name = "attendance-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.attendance_alerts.arn
  protocol  = "email"
  endpoint  = "alertas@midominio.com"
}

# Permiso para que Lambda publique en SNS
resource "aws_iam_role_policy" "lambda_sns_policy" {
  name = "lambda-sns-attendance-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.attendance_alerts.arn
      }
    ]
  })
}