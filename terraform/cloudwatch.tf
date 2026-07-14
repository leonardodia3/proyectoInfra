resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-attendance-api"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.dynamo_key.arn
}