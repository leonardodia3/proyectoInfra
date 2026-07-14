resource "aws_kms_key" "dynamo_key" {
  description             = "Clave KMS para cifrado en reposo de DynamoDB"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  # CKV2_AWS_64 - Policy de la clave KMS
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "dynamo_key_alias" {
  name          = "alias/attendance-dynamo-key"
  target_key_id = aws_kms_key.dynamo_key.key_id
}