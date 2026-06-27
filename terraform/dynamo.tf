resource "aws_dynamodb_table" "attendance" {

  name = "attendance"

  billing_mode = "PAY_PER_REQUEST"

  hash_key = "pk"

  range_key = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  # CKV_AWS_119 - Cifrado con KMS CMK
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamo_key.arn
  }

  # CKV_AWS_28 - Point-in-Time Recovery
  point_in_time_recovery {
    enabled = true
  }

}
