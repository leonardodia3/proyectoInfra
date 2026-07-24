data "aws_caller_identity" "current" {}

locals {
  lambda_role_names = {
    notify_alert       = "attendance-notify-alert-lambda-role"
    register_student   = "attendance-register-student-lambda-role"
    list_students      = "attendance-list-students-lambda-role"
    attendance         = "attendance-rfid-lambda-role"
    manual_attendance  = "attendance-manual-lambda-role"
    attendance_history = "attendance-history-lambda-role"
  }

  lambda_dynamodb_actions = {
    register_student = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query"
    ]
    list_students = [
      "dynamodb:Scan"
    ]
    attendance = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query"
    ]
    manual_attendance = [
      "dynamodb:GetItem",
      "dynamodb:PutItem"
    ]
    attendance_history = [
      "dynamodb:Query"
    ]
  }
}

resource "aws_iam_role" "lambda" {
  for_each = local.lambda_role_names
  name     = each.value

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  for_each = local.lambda_dynamodb_actions
  name     = "lambda-dynamodb-${each.key}-policy"
  role     = aws_iam_role.lambda[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect   = "Allow"
        Action   = each.value
        Resource = aws_dynamodb_table.attendance.arn
      }
      ], contains(["attendance", "register_student"], each.key) ? [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:Query"]
        Resource = "${aws_dynamodb_table.attendance.arn}/index/*"
      }
    ] : [])
  })
}

resource "aws_iam_role_policy" "lambda_kms" {
  for_each = aws_iam_role.lambda
  name     = "lambda-kms-${each.key}-policy"
  role     = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.dynamo_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  for_each   = aws_iam_role.lambda
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  for_each   = aws_iam_role.lambda
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}
