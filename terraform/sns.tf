resource "aws_sns_topic" "attendance_alerts" {
  name              = "attendance-alerts"
  kms_master_key_id = aws_kms_key.dynamo_key.key_id
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.attendance_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_iam_role_policy" "lambda_sns_policy" {
  for_each = toset(["notify_alert", "register_student"])
  name     = "lambda-sns-${each.key}-policy"
  role     = aws_iam_role.lambda[each.key].id

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
