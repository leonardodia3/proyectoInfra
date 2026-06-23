resource "aws_kms_key" "dynamo_key" {
  description             = "Clave KMS para cifrado en reposo de DynamoDB"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "dynamo_key_alias" {
  name          = "alias/attendance-dynamo-key"
  target_key_id = aws_kms_key.dynamo_key.key_id
}